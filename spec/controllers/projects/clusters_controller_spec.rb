# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ClustersController, feature_category: :deployment_management do
  include AccessMatchersForController
  include GoogleApi::CloudPlatformHelpers
  include KubernetesHelpers

  let_it_be_with_reload(:project) { create(:project) }

  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET index' do
    def go(params = {})
      get :index, params: params.reverse_merge(namespace_id: project.namespace.to_param, project_id: project)
    end

    describe 'functionality' do
      context 'when project has one or more clusters' do
        let!(:enabled_cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }
        let!(:disabled_cluster) { create(:cluster, :disabled, :provided_by_gcp, :production_environment, projects: [project]) }

        include_examples ':certificate_based_clusters feature flag index responses' do
          let(:subject) { go }
        end

        it 'lists available clusters and renders html' do
          go

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:index)
          expect(assigns(:clusters)).to match_array([enabled_cluster, disabled_cluster])
        end

        it 'lists available clusters with json serializer' do
          go(format: :json)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('cluster_list')
        end

        it 'sets the polling interval header for json requests' do
          go(format: :json)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers['Poll-Interval']).to eq("10000")
        end

        context 'when page is specified' do
          let(:last_page) { project.clusters.page.total_pages }
          let(:total_count) { project.clusters.page.total_count }

          before do
            allow(Clusters::Cluster).to receive(:default_per_page).and_return(1)
            create_list(:cluster, 2, :provided_by_gcp, :production_environment, projects: [project])
          end

          it 'redirects to the page' do
            expect(last_page).to be > 1

            go(page: last_page)

            expect(response).to have_gitlab_http_status(:ok)
            expect(assigns(:clusters).current_page).to eq(last_page)
          end

          it 'displays cluster list for associated page' do
            expect(last_page).to be > 1

            go(page: last_page, format: :json)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.headers['X-Page'].to_i).to eq(last_page)
            expect(response.headers['X-Total'].to_i).to eq(total_count)
          end
        end
      end

      context 'when project does not have a cluster' do
        it 'returns an empty state page' do
          go

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:index, partial: :empty_state)
          expect(assigns(:clusters)).to eq([])
        end
      end
    end

    describe 'security' do
      let(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

      it 'is allowed for admin when admin mode enabled', :enable_admin_mode do
        expect { go }.to be_allowed_for(:admin)
      end

      it 'is disabled for admin when admin mode disabled' do
        expect { go }.to be_denied_for(:admin)
      end

      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:maintainer).of(project) }
      it { expect { go }.to be_allowed_for(:developer).of(project) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'POST create for existing cluster' do
    let(:params) do
      {
        cluster: {
          name: 'new-cluster',
          managed: '1',
          platform_kubernetes_attributes: {
            api_url: 'http://my-url',
            token: 'test',
            namespace: 'aaa'
          }
        }
      }
    end

    def go
      post :create_user, params: params.merge(namespace_id: project.namespace, project_id: project)
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { go }
    end

    describe 'functionality' do
      context 'when creates a cluster' do
        it 'creates a new cluster' do
          expect { go }.to change { Clusters::Cluster.count }
            .and change { Clusters::Platforms::Kubernetes.count }

          expect(response).to redirect_to(project_cluster_path(project, project.clusters.first))

          expect(project.clusters.first).to be_user
          expect(project.clusters.first).to be_kubernetes
          expect(project.clusters.first).to be_namespace_per_environment
        end
      end

      context 'when creates a RBAC-enabled cluster' do
        let(:params) do
          {
            cluster: {
              name: 'new-cluster',
              platform_kubernetes_attributes: {
                api_url: 'http://my-url',
                token: 'test',
                namespace: 'aaa',
                authorization_type: 'rbac'
              }
            }
          }
        end

        it 'creates a new cluster' do
          expect { go }.to change { Clusters::Cluster.count }
            .and change { Clusters::Platforms::Kubernetes.count }

          expect(response).to redirect_to(project_cluster_path(project, project.clusters.first))

          cluster = project.clusters.first

          expect(cluster).to be_user
          expect(cluster).to be_kubernetes
          expect(cluster).to be_platform_kubernetes_rbac
          expect(cluster).to be_namespace_per_environment
        end
      end

      context 'when creates a user-managed cluster' do
        let(:params) do
          {
            cluster: {
              name: 'new-cluster',
              managed: '0',
              platform_kubernetes_attributes: {
                api_url: 'http://my-url',
                token: 'test',
                namespace: 'aaa',
                authorization_type: 'rbac'
              }
            }
          }
        end

        it 'creates a new user-managed cluster' do
          go
          cluster = project.clusters.first

          expect(cluster.managed?).to be_falsy
        end
      end
    end

    describe 'security' do
      before do
        stub_kubeclient_get_namespace('https://kubernetes.example.com', namespace: 'my-namespace')
      end

      it 'is allowed for admin when admin mode enabled', :enable_admin_mode do
        expect { go }.to be_allowed_for(:admin)
      end

      it 'is disabled for admin when admin mode disabled' do
        expect { go }.to be_denied_for(:admin)
      end

      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:maintainer).of(project) }
      it { expect { go }.to be_denied_for(:developer).of(project) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'DELETE clear cluster cache' do
    let(:cluster) { create(:cluster, :project, projects: [project]) }
    let!(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, cluster: cluster) }

    def go
      delete :clear_cache,
        params: {
          namespace_id: project.namespace,
          project_id: project,
          id: cluster
        }
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { go }
    end

    it 'deletes the namespaces associated with the cluster' do
      expect { go }.to change { Clusters::KubernetesNamespace.count }

      expect(response).to redirect_to(project_cluster_path(project, cluster))
      expect(cluster.kubernetes_namespaces).to be_empty
    end

    describe 'security' do
      it 'is allowed for admin when admin mode enabled', :enable_admin_mode do
        expect { go }.to be_allowed_for(:admin)
      end

      it 'is disabled for admin when admin mode disabled' do
        expect { go }.to be_denied_for(:admin)
      end

      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:maintainer).of(project) }
      it { expect { go }.to be_denied_for(:developer).of(project) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'GET cluster_status' do
    let(:cluster) { create(:cluster, :providing_by_gcp, projects: [project]) }

    def go
      get :cluster_status,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: cluster
        },
        format: :json
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { go }
    end

    describe 'functionality' do
      it "responds with matching schema" do
        go

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('cluster_status')
      end
    end

    describe 'security' do
      it 'is allowed for admin when admin mode enabled', :enable_admin_mode do
        expect { go }.to be_allowed_for(:admin)
      end

      it 'is disabled for admin when admin mode disabled' do
        expect { go }.to be_denied_for(:admin)
      end

      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:maintainer).of(project) }
      it { expect { go }.to be_denied_for(:developer).of(project) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'GET show' do
    let(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

    def go(tab: nil)
      get :show,
        params: {
          namespace_id: project.namespace,
          project_id: project,
          id: cluster,
          tab: tab
        }
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { go }
    end

    describe 'security' do
      it 'is allowed for admin when admin mode enabled', :enable_admin_mode do
        expect { go }.to be_allowed_for(:admin)
      end

      it 'is disabled for admin when admin mode disabled' do
        expect { go }.to be_denied_for(:admin)
      end

      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:maintainer).of(project) }
      it { expect { go }.to be_allowed_for(:developer).of(project) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'PUT update' do
    def go(format: :html)
      put :update, params: params.merge(
        namespace_id: project.namespace.to_param,
        project_id: project.to_param,
        id: cluster,
        format: format
      )
    end

    before do
      stub_kubeclient_get_namespace('https://kubernetes.example.com', namespace: 'my-namespace')
    end

    let(:cluster) { create(:cluster, :provided_by_user, projects: [project]) }

    let(:params) do
      {
        cluster: {
          enabled: false,
          name: 'my-new-cluster-name',
          managed: false,
          namespace_per_environment: false,
          platform_kubernetes_attributes: {
            namespace: 'my-namespace'
          }
        }
      }
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { go }
    end

    it "updates and redirects back to show page" do
      go

      cluster.reload
      expect(response).to redirect_to(project_cluster_path(project, cluster))
      expect(flash[:notice]).to eq('Kubernetes cluster was successfully updated.')
      expect(cluster.enabled).to be_falsey
      expect(cluster.name).to eq('my-new-cluster-name')
      expect(cluster).not_to be_managed
      expect(cluster).not_to be_namespace_per_environment
      expect(cluster.platform_kubernetes.namespace).to eq('my-namespace')
    end

    context 'when format is json' do
      context 'when changing parameters' do
        context 'when valid parameters are used' do
          let(:params) do
            {
              cluster: {
                enabled: false,
                name: 'my-new-cluster-name',
                managed: false,
                platform_kubernetes_attributes: {
                  namespace: 'my-namespace'
                }
              }
            }
          end

          it "updates and redirects back to show page" do
            go(format: :json)

            cluster.reload
            expect(response).to have_gitlab_http_status(:no_content)
            expect(cluster.enabled).to be_falsey
            expect(cluster.name).to eq('my-new-cluster-name')
            expect(cluster).not_to be_managed
            expect(cluster.platform_kubernetes.namespace).to eq('my-namespace')
          end
        end

        context 'when invalid parameters are used' do
          let(:params) do
            {
              cluster: {
                enabled: false,
                platform_kubernetes_attributes: {
                  namespace: 'my invalid namespace #@'
                }
              }
            }
          end

          it "rejects changes" do
            go(format: :json)

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end
    end

    describe 'security' do
      let_it_be(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

      it 'is allowed for admin when admin mode enabled', :enable_admin_mode do
        expect { go }.to be_allowed_for(:admin)
      end

      it 'is disabled for admin when admin mode disabled' do
        expect { go }.to be_denied_for(:admin)
      end

      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:maintainer).of(project) }
      it { expect { go }.to be_denied_for(:developer).of(project) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'DELETE destroy' do
    let!(:cluster) { create(:cluster, :provided_by_gcp, :production_environment, projects: [project]) }

    def go
      delete :destroy,
        params: {
          namespace_id: project.namespace,
          project_id: project,
          id: cluster
        }
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { go }
    end

    describe 'functionality' do
      context 'when cluster is provided by GCP' do
        context 'when cluster is created' do
          it "destroys and redirects back to clusters list" do
            expect { go }
              .to change { Clusters::Cluster.count }.by(-1)
              .and change { Clusters::Platforms::Kubernetes.count }.by(-1)
              .and change { Clusters::Providers::Gcp.count }.by(-1)

            expect(response).to redirect_to(project_clusters_path(project))
            expect(flash[:notice]).to eq('Kubernetes cluster integration was successfully removed.')
          end
        end

        context 'when cluster is being created' do
          let!(:cluster) { create(:cluster, :providing_by_gcp, :production_environment, projects: [project]) }

          it "destroys and redirects back to clusters list" do
            expect { go }
              .to change { Clusters::Cluster.count }.by(-1)
              .and change { Clusters::Providers::Gcp.count }.by(-1)

            expect(response).to redirect_to(project_clusters_path(project))
            expect(flash[:notice]).to eq('Kubernetes cluster integration was successfully removed.')
          end
        end
      end

      context 'when cluster is provided by user' do
        let!(:cluster) { create(:cluster, :provided_by_user, :production_environment, projects: [project]) }

        it "destroys and redirects back to clusters list" do
          expect { go }
            .to change { Clusters::Cluster.count }.by(-1)
            .and change { Clusters::Platforms::Kubernetes.count }.by(-1)
            .and change { Clusters::Providers::Gcp.count }.by(0)

          expect(response).to redirect_to(project_clusters_path(project))
          expect(flash[:notice]).to eq('Kubernetes cluster integration was successfully removed.')
        end
      end
    end

    describe 'security' do
      let_it_be(:cluster) { create(:cluster, :provided_by_gcp, :production_environment, projects: [project]) }

      it 'is allowed for admin when admin mode enabled', :enable_admin_mode do
        expect { go }.to be_allowed_for(:admin)
      end

      it 'is disabled for admin when admin mode disabled' do
        expect { go }.to be_denied_for(:admin)
      end

      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:maintainer).of(project) }
      it { expect { go }.to be_denied_for(:developer).of(project) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  context 'no project_id param' do
    it 'does not respond to any action without project_id param' do
      expect { get :index }.to raise_error(ActionController::UrlGenerationError)
    end
  end
end

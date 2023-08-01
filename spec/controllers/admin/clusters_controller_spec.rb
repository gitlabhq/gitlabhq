# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ClustersController, feature_category: :deployment_management do
  include AccessMatchersForController
  include GoogleApi::CloudPlatformHelpers

  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'GET #index' do
    def get_index(params = {})
      get :index, params: params
    end

    describe 'functionality' do
      context 'when instance has one or more clusters' do
        let!(:enabled_cluster) do
          create(:cluster, :provided_by_gcp, :instance)
        end

        let!(:disabled_cluster) do
          create(:cluster, :disabled, :provided_by_gcp, :production_environment, :instance)
        end

        include_examples ':certificate_based_clusters feature flag controller responses' do
          let(:subject) { get_index }
        end

        it 'lists available clusters and displays html' do
          get_index

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:index)
          expect(assigns(:clusters)).to match_array([enabled_cluster, disabled_cluster])
        end

        it 'lists available clusters and renders json serializer' do
          get_index(format: :json)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('cluster_list')
        end

        it 'sets the polling interval header for json requests' do
          get_index(format: :json)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers['Poll-Interval']).to eq("10000")
        end

        context 'when page is specified' do
          let(:last_page) { Clusters::Cluster.instance_type.page.total_pages }
          let(:total_count) { Clusters::Cluster.instance_type.page.total_count }

          before do
            allow(Clusters::Cluster).to receive(:default_per_page).and_return(1)
            create_list(:cluster, 2, :provided_by_gcp, :production_environment, :instance)
          end

          it 'redirects to the page' do
            expect(last_page).to be > 1

            get_index(page: last_page)

            expect(response).to have_gitlab_http_status(:ok)
            expect(assigns(:clusters).current_page).to eq(last_page)
          end

          it 'displays cluster list for associated page' do
            expect(last_page).to be > 1

            get_index(page: last_page, format: :json)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.headers['X-Page'].to_i).to eq(last_page)
            expect(response.headers['X-Total'].to_i).to eq(total_count)
          end
        end
      end

      context 'when instance does not have a cluster' do
        it 'returns an empty state page' do
          get_index

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:index, partial: :empty_state)
          expect(assigns(:clusters)).to eq([])
        end
      end
    end

    describe 'security' do
      let(:cluster) { create(:cluster, :provided_by_gcp, :instance) }

      it { expect { get_index }.to be_allowed_for(:admin) }
      it { expect { get_index }.to be_denied_for(:user) }
      it { expect { get_index }.to be_denied_for(:external) }
    end
  end

  describe 'POST #create_user' do
    let(:params) do
      {
        cluster: {
          name: 'new-cluster',
          platform_kubernetes_attributes: {
            api_url: 'http://my-url',
            token: 'test'
          }
        }
      }
    end

    def post_create_user
      post :create_user, params: params
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { post_create_user }
    end

    describe 'functionality' do
      context 'when creates a cluster' do
        it 'creates a new cluster' do
          expect { post_create_user }.to change { Clusters::Cluster.count }
            .and change { Clusters::Platforms::Kubernetes.count }

          cluster = Clusters::Cluster.instance_type.first

          expect(response).to redirect_to(admin_cluster_path(cluster))
          expect(cluster).to be_user
          expect(cluster).to be_kubernetes
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
                authorization_type: 'rbac'
              }
            }
          }
        end

        it 'creates a new cluster' do
          expect { post_create_user }.to change { Clusters::Cluster.count }
            .and change { Clusters::Platforms::Kubernetes.count }

          cluster = Clusters::Cluster.instance_type.first

          expect(response).to redirect_to(admin_cluster_path(cluster))
          expect(cluster).to be_user
          expect(cluster).to be_kubernetes
          expect(cluster).to be_platform_kubernetes_rbac
          expect(cluster).to be_namespace_per_environment
        end
      end
    end

    describe 'security' do
      it { expect { post_create_user }.to be_allowed_for(:admin) }
      it { expect { post_create_user }.to be_denied_for(:user) }
      it { expect { post_create_user }.to be_denied_for(:external) }
    end
  end

  describe 'DELETE clear cluster cache' do
    let(:cluster) { create(:cluster, :instance) }
    let!(:kubernetes_namespace) do
      create(:cluster_kubernetes_namespace,
        cluster: cluster,
        project: create(:project)
      )
    end

    def go
      delete :clear_cache, params: { id: cluster }
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { go }
    end

    it 'deletes the namespaces associated with the cluster' do
      expect { go }.to change { Clusters::KubernetesNamespace.count }

      expect(response).to redirect_to(admin_cluster_path(cluster))
      expect(cluster.kubernetes_namespaces).to be_empty
    end

    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'GET #cluster_status' do
    let(:cluster) { create(:cluster, :providing_by_gcp, :instance) }

    def get_cluster_status
      get :cluster_status,
        params: {
          id: cluster
        },
        format: :json
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { get_cluster_status }
    end

    describe 'functionality' do
      it 'responds with matching schema' do
        get_cluster_status

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('cluster_status')
      end
    end

    describe 'security' do
      it { expect { get_cluster_status }.to be_allowed_for(:admin) }
      it { expect { get_cluster_status }.to be_denied_for(:user) }
      it { expect { get_cluster_status }.to be_denied_for(:external) }
    end
  end

  describe 'GET #show' do
    let(:cluster) { create(:cluster, :provided_by_gcp, :instance) }

    def get_show(tab: nil)
      get :show,
        params: {
          id: cluster,
          tab: tab
        }
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { get_show }
    end

    describe 'security' do
      it { expect { get_show }.to be_allowed_for(:admin) }
      it { expect { get_show }.to be_denied_for(:user) }
      it { expect { get_show }.to be_denied_for(:external) }
    end
  end

  describe 'PUT #update' do
    def put_update(format: :html)
      put :update, params: params.merge(
        id: cluster,
        format: format
      )
    end

    let(:cluster) { create(:cluster, :provided_by_user, :instance) }
    let(:domain) { 'test-domain.com' }

    let(:params) do
      {
        cluster: {
          enabled: false,
          name: 'my-new-cluster-name',
          managed: false,
          namespace_per_environment: false,
          base_domain: domain
        }
      }
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { put_update }
    end

    it 'updates and redirects back to show page' do
      put_update

      cluster.reload
      expect(response).to redirect_to(admin_cluster_path(cluster))
      expect(flash[:notice]).to eq('Kubernetes cluster was successfully updated.')
      expect(cluster.enabled).to be_falsey
      expect(cluster.name).to eq('my-new-cluster-name')
      expect(cluster).not_to be_managed
      expect(cluster).not_to be_namespace_per_environment
      expect(cluster.domain).to eq('test-domain.com')
    end

    context 'when domain is invalid' do
      let(:domain) { 'http://not-a-valid-domain' }

      it 'does not update cluster attributes' do
        put_update

        cluster.reload
        expect(response).to render_template(:show)
        expect(cluster.name).not_to eq('my-new-cluster-name')
        expect(cluster.domain).not_to eq('test-domain.com')
      end
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
                namespace_per_environment: false,
                domain: domain
              }
            }
          end

          it 'updates and redirects back to show page' do
            put_update(format: :json)

            cluster.reload
            expect(response).to have_gitlab_http_status(:no_content)
            expect(cluster.enabled).to be_falsey
            expect(cluster.name).to eq('my-new-cluster-name')
            expect(cluster).not_to be_managed
            expect(cluster).not_to be_namespace_per_environment
          end
        end

        context 'when invalid parameters are used' do
          let(:params) do
            {
              cluster: {
                enabled: false,
                name: ''
              }
            }
          end

          it 'rejects changes' do
            put_update(format: :json)

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end
    end

    describe 'security' do
      let_it_be(:cluster) { create(:cluster, :provided_by_gcp, :instance) }

      it { expect { put_update }.to be_allowed_for(:admin) }
      it { expect { put_update }.to be_denied_for(:user) }
      it { expect { put_update }.to be_denied_for(:external) }
    end
  end

  describe 'DELETE #destroy' do
    let!(:cluster) { create(:cluster, :provided_by_gcp, :production_environment, :instance) }

    def delete_destroy
      delete :destroy,
        params: {
          id: cluster
        }
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { delete_destroy }
    end

    describe 'functionality' do
      context 'when cluster is provided by GCP' do
        context 'when cluster is created' do
          it 'destroys and redirects back to clusters list' do
            expect { delete_destroy }
              .to change { Clusters::Cluster.count }.by(-1)
              .and change { Clusters::Platforms::Kubernetes.count }.by(-1)
              .and change { Clusters::Providers::Gcp.count }.by(-1)

            expect(response).to redirect_to(admin_clusters_path)
            expect(flash[:notice]).to eq('Kubernetes cluster integration was successfully removed.')
          end
        end

        context 'when cluster is being created' do
          let!(:cluster) { create(:cluster, :providing_by_gcp, :production_environment, :instance) }

          it 'destroys and redirects back to clusters list' do
            expect { delete_destroy }
              .to change { Clusters::Cluster.count }.by(-1)
              .and change { Clusters::Providers::Gcp.count }.by(-1)

            expect(response).to redirect_to(admin_clusters_path)
            expect(flash[:notice]).to eq('Kubernetes cluster integration was successfully removed.')
          end
        end
      end

      context 'when cluster is provided by user' do
        let!(:cluster) { create(:cluster, :provided_by_user, :production_environment, :instance) }

        it 'destroys and redirects back to clusters list' do
          expect { delete_destroy }
            .to change { Clusters::Cluster.count }.by(-1)
            .and change { Clusters::Platforms::Kubernetes.count }.by(-1)
            .and change { Clusters::Providers::Gcp.count }.by(0)

          expect(response).to redirect_to(admin_clusters_path)
          expect(flash[:notice]).to eq('Kubernetes cluster integration was successfully removed.')
        end
      end
    end

    describe 'security' do
      let_it_be(:cluster) { create(:cluster, :provided_by_gcp, :production_environment, :instance) }

      it { expect { delete_destroy }.to be_allowed_for(:admin) }
      it { expect { delete_destroy }.to be_denied_for(:user) }
      it { expect { delete_destroy }.to be_denied_for(:external) }
    end
  end
end

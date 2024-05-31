# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ClustersController, feature_category: :deployment_management do
  include AccessMatchersForController
  include GoogleApi::CloudPlatformHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  before do
    group.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET index' do
    def go(params = {})
      get :index, params: params.reverse_merge(group_id: group)
    end

    describe 'functionality' do
      context 'when group has one or more clusters' do
        let_it_be(:enabled_cluster) do
          create(:cluster, :provided_by_gcp, cluster_type: :group_type, groups: [group])
        end

        let_it_be(:disabled_cluster) do
          create(:cluster, :disabled, :provided_by_gcp, :production_environment, cluster_type: :group_type, groups: [group])
        end

        include_examples ':certificate_based_clusters feature flag controller responses' do
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
          let(:last_page) { group.clusters.page.total_pages }
          let(:total_count) { group.clusters.page.total_count }

          before do
            allow(Clusters::Cluster).to receive(:default_per_page).and_return(1)
            create_list(:cluster, 2, :provided_by_gcp, :production_environment, cluster_type: :group_type, groups: [group])
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

      context 'when group does not have a cluster' do
        it 'returns an empty state page' do
          go

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:index, partial: :empty_state)
          expect(assigns(:clusters)).to eq([])
        end
      end
    end

    describe 'security' do
      let_it_be(:cluster) { create(:cluster, :provided_by_gcp, cluster_type: :group_type, groups: [group]) }

      it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { expect { go }.to be_allowed_for(:admin) }
      it('is denied for admin when admin mode is disabled') { expect { go }.to be_denied_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(group) }
      it { expect { go }.to be_allowed_for(:maintainer).of(group) }
      it { expect { go }.to be_allowed_for(:developer).of(group) }
      it { expect { go }.to be_denied_for(:reporter).of(group) }
      it { expect { go }.to be_denied_for(:guest).of(group) }
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
            token: 'test'
          }
        }
      }
    end

    def go
      post :create_user, params: params.merge(group_id: group)
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { go }
    end

    describe 'functionality' do
      context 'when creates a cluster' do
        it 'creates a new cluster' do
          expect { go }.to change { Clusters::Cluster.count }
            .and change { Clusters::Platforms::Kubernetes.count }

          cluster = group.clusters.first

          expect(response).to redirect_to(group_cluster_path(group, cluster))
          expect(cluster).to be_user
          expect(cluster).to be_kubernetes
          expect(cluster).to be_managed
          expect(cluster).to be_namespace_per_environment
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
          expect { go }.to change { Clusters::Cluster.count }
            .and change { Clusters::Platforms::Kubernetes.count }

          cluster = group.clusters.first

          expect(response).to redirect_to(group_cluster_path(group, cluster))
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
                authorization_type: 'rbac'
              }
            }
          }
        end

        it 'creates a new user-managed cluster' do
          go

          cluster = group.clusters.first
          expect(cluster.managed?).to be_falsy
        end
      end
    end

    describe 'security' do
      it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { expect { go }.to be_allowed_for(:admin) }
      it('is denied for admin when admin mode is disabled') { expect { go }.to be_denied_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(group) }
      it { expect { go }.to be_allowed_for(:maintainer).of(group) }
      it { expect { go }.to be_denied_for(:developer).of(group) }
      it { expect { go }.to be_denied_for(:reporter).of(group) }
      it { expect { go }.to be_denied_for(:guest).of(group) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'DELETE clear cluster cache' do
    let_it_be(:cluster) { create(:cluster, :group, groups: [group]) }
    let_it_be(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, cluster: cluster, project: create(:project)) }

    def go
      delete :clear_cache,
        params: {
          group_id: group,
          id: cluster
        }
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { go }
    end

    it 'deletes the namespaces associated with the cluster' do
      expect { go }.to change { Clusters::KubernetesNamespace.count }

      expect(response).to redirect_to(group_cluster_path(group, cluster))
      expect(cluster.kubernetes_namespaces).to be_empty
    end

    describe 'security' do
      it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { expect { go }.to be_allowed_for(:admin) }
      it('is denied for admin when admin mode is disabled') { expect { go }.to be_denied_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(group) }
      it { expect { go }.to be_allowed_for(:maintainer).of(group) }
      it { expect { go }.to be_denied_for(:developer).of(group) }
      it { expect { go }.to be_denied_for(:reporter).of(group) }
      it { expect { go }.to be_denied_for(:guest).of(group) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'GET cluster_status' do
    let(:cluster) { create(:cluster, :providing_by_gcp, cluster_type: :group_type, groups: [group]) }

    def go
      get :cluster_status,
        params: {
          group_id: group.to_param,
          id: cluster
        },
        format: :json
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { go }
    end

    describe 'functionality' do
      it 'responds with matching schema' do
        go

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('cluster_status')
      end
    end

    describe 'security' do
      it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { expect { go }.to be_allowed_for(:admin) }
      it('is denied for admin when admin mode is disabled') { expect { go }.to be_denied_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(group) }
      it { expect { go }.to be_allowed_for(:maintainer).of(group) }
      it { expect { go }.to be_denied_for(:developer).of(group) }
      it { expect { go }.to be_denied_for(:reporter).of(group) }
      it { expect { go }.to be_denied_for(:guest).of(group) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'GET show' do
    let(:cluster) { create(:cluster, :provided_by_gcp, cluster_type: :group_type, groups: [group]) }

    def go(tab: nil)
      get :show,
        params: {
          group_id: group,
          id: cluster,
          tab: tab
        }
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { go }
    end

    describe 'security' do
      it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { expect { go }.to be_allowed_for(:admin) }
      it('is denied for admin when admin mode is disabled') { expect { go }.to be_denied_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(group) }
      it { expect { go }.to be_allowed_for(:maintainer).of(group) }
      it { expect { go }.to be_allowed_for(:developer).of(group) }
      it { expect { go }.to be_denied_for(:reporter).of(group) }
      it { expect { go }.to be_denied_for(:guest).of(group) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'PUT update' do
    def go(format: :html)
      put :update, params: params.merge(
        group_id: group.to_param,
        id: cluster,
        format: format
      )
    end

    let(:cluster) { create(:cluster, :provided_by_user, cluster_type: :group_type, groups: [group]) }
    let(:domain) { 'test-domain.com' }

    let(:params) do
      {
        cluster: {
          enabled: false,
          name: 'my-new-cluster-name',
          managed: false,
          base_domain: domain
        }
      }
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { go }
    end

    it 'updates and redirects back to show page' do
      go

      cluster.reload
      expect(response).to redirect_to(group_cluster_path(group, cluster))
      expect(flash[:notice]).to eq('Kubernetes cluster was successfully updated.')
      expect(cluster.enabled).to be_falsey
      expect(cluster.name).to eq('my-new-cluster-name')
      expect(cluster).not_to be_managed
      expect(cluster.domain).to eq('test-domain.com')
    end

    context 'when domain is invalid' do
      let(:domain) { 'http://not-a-valid-domain' }

      it 'does not update cluster attributes' do
        go

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
            go(format: :json)

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
            go(format: :json)

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end
    end

    describe 'security' do
      let_it_be(:cluster) { create(:cluster, :provided_by_gcp, cluster_type: :group_type, groups: [group]) }

      it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { expect { go }.to be_allowed_for(:admin) }
      it('is denied for admin when admin mode is disabled') { expect { go }.to be_denied_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(group) }
      it { expect { go }.to be_allowed_for(:maintainer).of(group) }
      it { expect { go }.to be_denied_for(:developer).of(group) }
      it { expect { go }.to be_denied_for(:reporter).of(group) }
      it { expect { go }.to be_denied_for(:guest).of(group) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'DELETE destroy' do
    let_it_be(:cluster) { create(:cluster, :provided_by_gcp, :production_environment, cluster_type: :group_type, groups: [group]) }

    def go
      delete :destroy,
        params: {
          group_id: group,
          id: cluster
        }
    end

    include_examples ':certificate_based_clusters feature flag controller responses' do
      let(:subject) { go }
    end

    describe 'functionality' do
      context 'when cluster is provided by GCP' do
        context 'when cluster is created' do
          it 'destroys and redirects back to clusters list' do
            expect { go }
              .to change { Clusters::Cluster.count }.by(-1)
              .and change { Clusters::Platforms::Kubernetes.count }.by(-1)
              .and change { Clusters::Providers::Gcp.count }.by(-1)

            expect(response).to redirect_to(group_clusters_path(group))
            expect(flash[:notice]).to eq('Kubernetes cluster integration was successfully removed.')
          end
        end

        context 'when cluster is being created' do
          let_it_be(:cluster) { create(:cluster, :providing_by_gcp, :production_environment, cluster_type: :group_type, groups: [group]) }

          it 'destroys and redirects back to clusters list' do
            expect { go }
              .to change { Clusters::Cluster.count }.by(-1)
              .and change { Clusters::Providers::Gcp.count }.by(-1)

            expect(response).to redirect_to(group_clusters_path(group))
            expect(flash[:notice]).to eq('Kubernetes cluster integration was successfully removed.')
          end
        end
      end

      context 'when cluster is provided by user' do
        let_it_be(:cluster) { create(:cluster, :provided_by_user, :production_environment, cluster_type: :group_type, groups: [group]) }

        it 'destroys and redirects back to clusters list' do
          expect { go }
            .to change { Clusters::Cluster.count }.by(-1)
            .and change { Clusters::Platforms::Kubernetes.count }.by(-1)
            .and change { Clusters::Providers::Gcp.count }.by(0)

          expect(response).to redirect_to(group_clusters_path(group))
          expect(flash[:notice]).to eq('Kubernetes cluster integration was successfully removed.')
        end
      end
    end

    describe 'security' do
      let_it_be(:cluster) { create(:cluster, :provided_by_gcp, :production_environment, cluster_type: :group_type, groups: [group]) }

      it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { expect { go }.to be_allowed_for(:admin) }
      it('is denied for admin when admin mode is disabled') { expect { go }.to be_denied_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(group) }
      it { expect { go }.to be_allowed_for(:maintainer).of(group) }
      it { expect { go }.to be_denied_for(:developer).of(group) }
      it { expect { go }.to be_denied_for(:reporter).of(group) }
      it { expect { go }.to be_denied_for(:guest).of(group) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  context 'no group_id param' do
    it 'does not respond to any action without group_id param' do
      expect { get :index }.to raise_error(ActionController::UrlGenerationError)
    end
  end
end

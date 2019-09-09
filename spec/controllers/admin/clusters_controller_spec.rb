# frozen_string_literal: true

require 'spec_helper'

describe Admin::ClustersController do
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

        it 'lists available clusters' do
          get_index

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:index)
          expect(assigns(:clusters)).to match_array([enabled_cluster, disabled_cluster])
        end

        context 'when page is specified' do
          let(:last_page) { Clusters::Cluster.instance_type.page.total_pages }

          before do
            allow(Clusters::Cluster).to receive(:paginates_per).and_return(1)
            create_list(:cluster, 2, :provided_by_gcp, :production_environment, :instance)
          end

          it 'redirects to the page' do
            get_index(page: last_page)

            expect(response).to have_gitlab_http_status(:ok)
            expect(assigns(:clusters).current_page).to eq(last_page)
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

  describe 'GET #new' do
    def get_new(provider: 'gke')
      get :new, params: { provider: provider }
    end

    describe 'functionality for new cluster' do
      context 'when omniauth has been configured' do
        let(:key) { 'secret-key' }
        let(:session_key_for_redirect_uri) do
          GoogleApi::CloudPlatform::Client.session_key_for_redirect_uri(key)
        end

        before do
          stub_feature_flags(create_eks_clusters: false)
          allow(SecureRandom).to receive(:hex).and_return(key)
        end

        it 'has authorize_url' do
          get_new

          expect(assigns(:authorize_url)).to include(key)
          expect(session[session_key_for_redirect_uri]).to eq(new_admin_cluster_path)
        end

        context 'when create_eks_clusters feature flag is enabled' do
          before do
            stub_feature_flags(create_eks_clusters: true)
          end

          context 'when selected provider is gke and no valid gcp token exists' do
            it 'redirects to gcp authorize_url' do
              get_new

              expect(response).to redirect_to(assigns(:authorize_url))
            end
          end
        end
      end

      context 'when omniauth has not configured' do
        before do
          stub_omniauth_setting(providers: [])
        end

        it 'does not have authorize_url' do
          get_new

          expect(assigns(:authorize_url)).to be_nil
        end
      end

      context 'when access token is valid' do
        before do
          stub_google_api_validate_token
        end

        it 'has new object' do
          get_new

          expect(assigns(:gcp_cluster)).to be_an_instance_of(Clusters::ClusterPresenter)
        end
      end

      context 'when access token is expired' do
        before do
          stub_google_api_expired_token
        end

        it { expect(@valid_gcp_token).to be_falsey }
      end

      context 'when access token is not stored in session' do
        it { expect(@valid_gcp_token).to be_falsey }
      end
    end

    describe 'functionality for existing cluster' do
      it 'has new object' do
        get_new

        expect(assigns(:user_cluster)).to be_an_instance_of(Clusters::ClusterPresenter)
      end
    end

    describe 'security' do
      it { expect { get_new }.to be_allowed_for(:admin) }
      it { expect { get_new }.to be_denied_for(:user) }
      it { expect { get_new }.to be_denied_for(:external) }
    end
  end

  describe 'POST #create_gcp' do
    let(:legacy_abac_param) { 'true' }
    let(:params) do
      {
        cluster: {
          name: 'new-cluster',
          provider_gcp_attributes: {
            gcp_project_id: 'gcp-project-12345',
            legacy_abac: legacy_abac_param
          }
        }
      }
    end

    def post_create_gcp
      post :create_gcp, params: params
    end

    describe 'functionality' do
      context 'when access token is valid' do
        before do
          stub_google_api_validate_token
        end

        it 'creates a new cluster' do
          expect(ClusterProvisionWorker).to receive(:perform_async)
          expect { post_create_gcp }.to change { Clusters::Cluster.count }
            .and change { Clusters::Providers::Gcp.count }

          cluster = Clusters::Cluster.instance_type.first

          expect(response).to redirect_to(admin_cluster_path(cluster))
          expect(cluster).to be_gcp
          expect(cluster).to be_kubernetes
          expect(cluster.provider_gcp).to be_legacy_abac
        end

        context 'when legacy_abac param is false' do
          let(:legacy_abac_param) { 'false' }

          it 'creates a new cluster with legacy_abac_disabled' do
            expect(ClusterProvisionWorker).to receive(:perform_async)
            expect { post_create_gcp }.to change { Clusters::Cluster.count }
              .and change { Clusters::Providers::Gcp.count }
            expect(Clusters::Cluster.instance_type.first.provider_gcp).not_to be_legacy_abac
          end
        end
      end

      context 'when access token is expired' do
        before do
          stub_google_api_expired_token
        end

        it { expect(@valid_gcp_token).to be_falsey }
      end

      context 'when access token is not stored in session' do
        it { expect(@valid_gcp_token).to be_falsey }
      end
    end

    describe 'security' do
      before do
        allow_any_instance_of(described_class)
          .to receive(:token_in_session).and_return('token')
        allow_any_instance_of(described_class)
          .to receive(:expires_at_in_session).and_return(1.hour.since.to_i.to_s)
        allow_any_instance_of(GoogleApi::CloudPlatform::Client)
          .to receive(:projects_zones_clusters_create) do
          OpenStruct.new(
            self_link: 'projects/gcp-project-12345/zones/us-central1-a/operations/ope-123',
            status: 'RUNNING'
          )
        end

        allow(WaitForClusterCreationWorker).to receive(:perform_in).and_return(nil)
      end

      it { expect { post_create_gcp }.to be_allowed_for(:admin) }
      it { expect { post_create_gcp }.to be_denied_for(:user) }
      it { expect { post_create_gcp }.to be_denied_for(:external) }
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

    describe 'functionality' do
      context 'when creates a cluster' do
        it 'creates a new cluster' do
          expect(ClusterProvisionWorker).to receive(:perform_async)

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
          expect(ClusterProvisionWorker).to receive(:perform_async)

          expect { post_create_user }.to change { Clusters::Cluster.count }
            .and change { Clusters::Platforms::Kubernetes.count }

          cluster = Clusters::Cluster.instance_type.first

          expect(response).to redirect_to(admin_cluster_path(cluster))
          expect(cluster).to be_user
          expect(cluster).to be_kubernetes
          expect(cluster).to be_platform_kubernetes_rbac
        end
      end
    end

    describe 'security' do
      it { expect { post_create_user }.to be_allowed_for(:admin) }
      it { expect { post_create_user }.to be_denied_for(:user) }
      it { expect { post_create_user }.to be_denied_for(:external) }
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

    describe 'functionality' do
      it 'responds with matching schema' do
        get_cluster_status

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('cluster_status')
      end

      it 'invokes schedule_status_update on each application' do
        expect_any_instance_of(Clusters::Applications::Ingress).to receive(:schedule_status_update)

        get_cluster_status
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

    def get_show
      get :show,
        params: {
          id: cluster
        }
    end

    describe 'functionality' do
      it 'responds successfully' do
        get_show

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:cluster)).to eq(cluster)
      end
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
          base_domain: domain
        }
      }
    end

    it 'updates and redirects back to show page' do
      put_update

      cluster.reload
      expect(response).to redirect_to(admin_cluster_path(cluster))
      expect(flash[:notice]).to eq('Kubernetes cluster was successfully updated.')
      expect(cluster.enabled).to be_falsey
      expect(cluster.name).to eq('my-new-cluster-name')
      expect(cluster).not_to be_managed
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
                domain: domain
              }
            }
          end

          it 'updates and redirects back to show page' do
            put_update(format: :json)

            cluster.reload
            expect(response).to have_http_status(:no_content)
            expect(cluster.enabled).to be_falsey
            expect(cluster.name).to eq('my-new-cluster-name')
            expect(cluster).not_to be_managed
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

            expect(response).to have_http_status(:bad_request)
          end
        end
      end
    end

    describe 'security' do
      set(:cluster) { create(:cluster, :provided_by_gcp, :instance) }

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
      set(:cluster) { create(:cluster, :provided_by_gcp, :production_environment, :instance) }

      it { expect { delete_destroy }.to be_allowed_for(:admin) }
      it { expect { delete_destroy }.to be_denied_for(:user) }
      it { expect { delete_destroy }.to be_denied_for(:external) }
    end
  end
end

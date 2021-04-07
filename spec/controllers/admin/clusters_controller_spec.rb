# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ClustersController do
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
            create_list(:cluster, 30, :provided_by_gcp, :production_environment, :instance)
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

  describe 'GET #new' do
    let(:user) { admin }

    def go(provider: 'gcp')
      get :new, params: { provider: provider }
    end

    describe 'functionality for new cluster' do
      context 'when omniauth has been configured' do
        let(:key) { 'secret-key' }
        let(:session_key_for_redirect_uri) do
          GoogleApi::CloudPlatform::Client.session_key_for_redirect_uri(key)
        end

        context 'when selected provider is gke and no valid gcp token exists' do
          it 'redirects to gcp authorize_url' do
            go

            expect(response).to redirect_to(assigns(:authorize_url))
          end
        end
      end

      context 'when omniauth has not configured' do
        before do
          stub_omniauth_setting(providers: [])
        end

        it 'does not have authorize_url' do
          go

          expect(assigns(:authorize_url)).to be_nil
        end
      end

      context 'when access token is valid' do
        before do
          stub_google_api_validate_token
        end

        it 'has new object' do
          go

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
        go

        expect(assigns(:user_cluster)).to be_an_instance_of(Clusters::ClusterPresenter)
      end
    end

    include_examples 'GET new cluster shared examples'

    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  it_behaves_like 'GET #metrics_dashboard for dashboard', 'Cluster health' do
    let(:cluster) { create(:cluster, :instance, :provided_by_gcp) }

    let(:metrics_dashboard_req_params) do
      {
        id: cluster.id
      }
    end
  end

  describe 'GET #prometheus_proxy' do
    let(:user) { admin }
    let(:proxyable) do
      create(:cluster, :instance, :provided_by_gcp)
    end

    it_behaves_like 'metrics dashboard prometheus api proxy' do
      context 'with anonymous user' do
        let(:prometheus_body) { nil }

        before do
          sign_out(admin)
        end

        it 'returns 404' do
          get :prometheus_proxy, params: prometheus_proxy_params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
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
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:token_in_session).and_return('token')
          allow(instance).to receive(:expires_at_in_session).and_return(1.hour.since.to_i.to_s)
        end
        allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |instance|
          allow(instance).to receive(:projects_zones_clusters_create) do
            OpenStruct.new(
              self_link: 'projects/gcp-project-12345/zones/us-central1-a/operations/ope-123',
              status: 'RUNNING'
            )
          end
        end

        allow(WaitForClusterCreationWorker).to receive(:perform_in).and_return(nil)
      end

      it { expect { post_create_gcp }.to be_allowed_for(:admin) }
      it { expect { post_create_gcp }.to be_denied_for(:user) }
      it { expect { post_create_gcp }.to be_denied_for(:external) }
    end
  end

  describe 'POST #create_aws' do
    let(:params) do
      {
        cluster: {
          name: 'new-cluster',
          provider_aws_attributes: {
            key_name: 'key',
            role_arn: 'arn:role',
            region: 'region',
            vpc_id: 'vpc',
            instance_type: 'instance type',
            num_nodes: 3,
            security_group_id: 'security group',
            subnet_ids: %w(subnet1 subnet2)
          }
        }
      }
    end

    def post_create_aws
      post :create_aws, params: params
    end

    it 'creates a new cluster' do
      expect(ClusterProvisionWorker).to receive(:perform_async)
      expect { post_create_aws }.to change { Clusters::Cluster.count }
        .and change { Clusters::Providers::Aws.count }

      cluster = Clusters::Cluster.instance_type.first

      expect(response).to have_gitlab_http_status(:created)
      expect(response.location).to eq(admin_cluster_path(cluster))
      expect(cluster).to be_aws
      expect(cluster).to be_kubernetes
    end

    context 'params are invalid' do
      let(:params) do
        {
          cluster: { name: '' }
        }
      end

      it 'does not create a cluster' do
        expect { post_create_aws }.not_to change { Clusters::Cluster.count }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(response.media_type).to eq('application/json')
        expect(response.body).to include('is invalid')
      end
    end

    describe 'security' do
      before do
        allow(WaitForClusterCreationWorker).to receive(:perform_in)
      end

      it { expect { post_create_aws }.to be_allowed_for(:admin) }
      it { expect { post_create_aws }.to be_denied_for(:user) }
      it { expect { post_create_aws }.to be_denied_for(:external) }
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

  describe 'POST authorize AWS role for EKS cluster' do
    let!(:role) { create(:aws_role, user: admin) }

    let(:role_arn) { 'arn:new-role' }
    let(:params) do
      {
        cluster: {
          role_arn: role_arn
        }
      }
    end

    def go
      post :authorize_aws_role, params: params
    end

    before do
      allow(Clusters::Aws::FetchCredentialsService).to receive(:new)
        .and_return(double(execute: double))
    end

    it 'updates the associated role with the supplied ARN' do
      go

      expect(response).to have_gitlab_http_status(:ok)
      expect(role.reload.role_arn).to eq(role_arn)
    end

    context 'supplied role is invalid' do
      let(:role_arn) { 'invalid-role' }

      it 'does not update the associated role' do
        expect { go }.not_to change { role.role_arn }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    describe 'security' do
      before do
        allow_next_instance_of(Clusters::Aws::AuthorizeRoleService) do |service|
          response = double(status: :ok, body: double)

          allow(service).to receive(:execute).and_return(response)
        end
      end

      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
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

    describe 'functionality' do
      it 'responds with matching schema' do
        get_cluster_status

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('cluster_status')
      end

      it 'invokes schedule_status_update on each application' do
        expect_next_instance_of(Clusters::Applications::Ingress) do |instance|
          expect(instance).to receive(:schedule_status_update)
        end

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

    def get_show(tab: nil)
      get :show,
        params: {
          id: cluster,
          tab: tab
        }
    end

    describe 'functionality' do
      render_views

      it 'responds successfully' do
        get_show

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:cluster)).to eq(cluster)
      end

      it 'renders integration tab view' do
        get_show(tab: 'integrations')

        expect(response).to render_template('clusters/clusters/_integrations')
        expect(response).to have_gitlab_http_status(:ok)
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
          namespace_per_environment: false,
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

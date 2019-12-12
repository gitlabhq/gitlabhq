# frozen_string_literal: true

require 'spec_helper'

describe Projects::ClustersController do
  include AccessMatchersForController
  include GoogleApi::CloudPlatformHelpers
  include KubernetesHelpers

  let_it_be(:project) { create(:project) }

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
        let(:project) { create(:project) }
        let!(:enabled_cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }
        let!(:disabled_cluster) { create(:cluster, :disabled, :provided_by_gcp, :production_environment, projects: [project]) }
        it 'lists available clusters' do
          go

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:index)
          expect(assigns(:clusters)).to match_array([enabled_cluster, disabled_cluster])
        end

        context 'when page is specified' do
          let(:last_page) { project.clusters.page.total_pages }

          before do
            allow(Clusters::Cluster).to receive(:paginates_per).and_return(1)
            create_list(:cluster, 2, :provided_by_gcp, :production_environment, projects: [project])
          end

          it 'redirects to the page' do
            go(page: last_page)

            expect(response).to have_gitlab_http_status(:ok)
            expect(assigns(:clusters).current_page).to eq(last_page)
          end
        end
      end

      context 'when project does not have a cluster' do
        let(:project) { create(:project) }

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

      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:maintainer).of(project) }
      it { expect { go }.to be_denied_for(:developer).of(project) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'GET new' do
    def go(provider: 'gcp')
      get :new, params: {
        namespace_id: project.namespace,
        project_id: project,
        provider: provider
      }
    end

    describe 'functionality for new cluster' do
      context 'when omniauth has been configured' do
        let(:key) { 'secret-key' }
        let(:session_key_for_redirect_uri) do
          GoogleApi::CloudPlatform::Client.session_key_for_redirect_uri(key)
        end

        before do
          allow(SecureRandom).to receive(:hex).and_return(key)
        end

        it 'redirects to gcp authorize_url' do
          go

          expect(assigns(:authorize_url)).to include(key)
          expect(session[session_key_for_redirect_uri]).to eq(new_project_cluster_path(project, provider: :gcp))
          expect(response).to redirect_to(assigns(:authorize_url))
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

    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:maintainer).of(project) }
      it { expect { go }.to be_denied_for(:developer).of(project) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'POST create for new cluster' do
    let(:legacy_abac_param) { 'true' }
    let(:params) do
      {
        cluster: {
          name: 'new-cluster',
          managed: '1',
          provider_gcp_attributes: {
            gcp_project_id: 'gcp-project-12345',
            legacy_abac: legacy_abac_param
          }
        }
      }
    end

    def go
      post :create_gcp, params: params.merge(namespace_id: project.namespace, project_id: project)
    end

    describe 'functionality' do
      context 'when access token is valid' do
        before do
          stub_google_api_validate_token
        end

        it 'creates a new cluster' do
          expect(ClusterProvisionWorker).to receive(:perform_async)
          expect { go }.to change { Clusters::Cluster.count }
            .and change { Clusters::Providers::Gcp.count }
          expect(response).to redirect_to(project_cluster_path(project, project.clusters.first))
          expect(project.clusters.first).to be_gcp
          expect(project.clusters.first).to be_kubernetes
          expect(project.clusters.first.provider_gcp).to be_legacy_abac
          expect(project.clusters.first.managed?).to be_truthy
        end

        context 'when legacy_abac param is false' do
          let(:legacy_abac_param) { 'false' }

          it 'creates a new cluster with legacy_abac_disabled' do
            expect(ClusterProvisionWorker).to receive(:perform_async)
            expect { go }.to change { Clusters::Cluster.count }
              .and change { Clusters::Providers::Gcp.count }
            expect(project.clusters.first.provider_gcp).not_to be_legacy_abac
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

      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:maintainer).of(project) }
      it { expect { go }.to be_denied_for(:developer).of(project) }
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

    describe 'functionality' do
      context 'when creates a cluster' do
        it 'creates a new cluster' do
          expect(ClusterProvisionWorker).to receive(:perform_async)

          expect { go }.to change { Clusters::Cluster.count }
            .and change { Clusters::Platforms::Kubernetes.count }

          expect(response).to redirect_to(project_cluster_path(project, project.clusters.first))

          expect(project.clusters.first).to be_user
          expect(project.clusters.first).to be_kubernetes
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
          expect(ClusterProvisionWorker).to receive(:perform_async)

          expect { go }.to change { Clusters::Cluster.count }
            .and change { Clusters::Platforms::Kubernetes.count }

          expect(response).to redirect_to(project_cluster_path(project, project.clusters.first))

          cluster = project.clusters.first

          expect(cluster).to be_user
          expect(cluster).to be_kubernetes
          expect(cluster).to be_platform_kubernetes_rbac
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

      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:maintainer).of(project) }
      it { expect { go }.to be_denied_for(:developer).of(project) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
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
      post :create_aws, params: params.merge(namespace_id: project.namespace, project_id: project)
    end

    it 'creates a new cluster' do
      expect(ClusterProvisionWorker).to receive(:perform_async)
      expect { post_create_aws }.to change { Clusters::Cluster.count }
        .and change { Clusters::Providers::Aws.count }

      cluster = project.clusters.first

      expect(response.status).to eq(201)
      expect(response.location).to eq(project_cluster_path(project, cluster))
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

        expect(response.status).to eq(422)
        expect(response.content_type).to eq('application/json')
        expect(response.body).to include('is invalid')
      end
    end

    describe 'security' do
      before do
        allow(WaitForClusterCreationWorker).to receive(:perform_in)
      end

      it { expect { post_create_aws }.to be_allowed_for(:admin) }
      it { expect { post_create_aws }.to be_allowed_for(:owner).of(project) }
      it { expect { post_create_aws }.to be_allowed_for(:maintainer).of(project) }
      it { expect { post_create_aws }.to be_denied_for(:developer).of(project) }
      it { expect { post_create_aws }.to be_denied_for(:reporter).of(project) }
      it { expect { post_create_aws }.to be_denied_for(:guest).of(project) }
      it { expect { post_create_aws }.to be_denied_for(:user) }
      it { expect { post_create_aws }.to be_denied_for(:external) }
    end
  end

  describe 'POST authorize AWS role for EKS cluster' do
    let(:role_arn) { 'arn:aws:iam::123456789012:role/role-name' }
    let(:role_external_id) { '12345' }

    let(:params) do
      {
        cluster: {
          role_arn: role_arn,
          role_external_id: role_external_id
        }
      }
    end

    def go
      post :authorize_aws_role, params: params.merge(namespace_id: project.namespace, project_id: project)
    end

    before do
      allow(Clusters::Aws::FetchCredentialsService).to receive(:new)
        .and_return(double(execute: double))
    end

    it 'creates an Aws::Role record' do
      expect { go }.to change { Aws::Role.count }

      expect(response.status).to eq 200

      role = Aws::Role.last
      expect(role.user).to eq user
      expect(role.role_arn).to eq role_arn
      expect(role.role_external_id).to eq role_external_id
    end

    context 'role cannot be created' do
      let(:role_arn) { 'invalid-role' }

      it 'does not create a record' do
        expect { go }.not_to change { Aws::Role.count }

        expect(response.status).to eq 422
      end
    end

    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
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

    it 'deletes the namespaces associated with the cluster' do
      expect { go }.to change { Clusters::KubernetesNamespace.count }

      expect(response).to redirect_to(project_cluster_path(project, cluster))
      expect(cluster.kubernetes_namespaces).to be_empty
    end

    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
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

    describe 'functionality' do
      it "responds with matching schema" do
        go

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('cluster_status')
      end

      it 'invokes schedule_status_update on each application' do
        expect_any_instance_of(Clusters::Applications::Ingress).to receive(:schedule_status_update)

        go
      end
    end

    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
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

    def go
      get :show,
        params: {
          namespace_id: project.namespace,
          project_id: project,
          id: cluster
        }
    end

    describe 'functionality' do
      it "renders view" do
        go

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:cluster)).to eq(cluster)
      end
    end

    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:maintainer).of(project) }
      it { expect { go }.to be_denied_for(:developer).of(project) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end

  describe 'PUT update' do
    def go(format: :html)
      put :update, params: params.merge(namespace_id: project.namespace.to_param,
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
          platform_kubernetes_attributes: {
            namespace: 'my-namespace'
          }
        }
      }
    end

    it "updates and redirects back to show page" do
      go

      cluster.reload
      expect(response).to redirect_to(project_cluster_path(project, cluster))
      expect(flash[:notice]).to eq('Kubernetes cluster was successfully updated.')
      expect(cluster.enabled).to be_falsey
      expect(cluster.name).to eq('my-new-cluster-name')
      expect(cluster).not_to be_managed
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
            expect(response).to have_http_status(:no_content)
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

            expect(response).to have_http_status(:bad_request)
          end
        end
      end
    end

    describe 'security' do
      let_it_be(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

      it { expect { go }.to be_allowed_for(:admin) }
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

      it { expect { go }.to be_allowed_for(:admin) }
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

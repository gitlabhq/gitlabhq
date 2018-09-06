require 'spec_helper'

describe Projects::ClustersController do
  include AccessMatchersForController
  include GoogleApi::CloudPlatformHelpers

  set(:project) { create(:project) }

  describe 'GET index' do
    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

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
            get :index, namespace_id: project.namespace, project_id: project, page: last_page
          end

          it 'redirects to the page' do
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

    def go
      get :index, namespace_id: project.namespace.to_param, project_id: project
    end
  end

  describe 'GET new' do
    describe 'functionality for new cluster' do
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      context 'when omniauth has been configured' do
        let(:key) { 'secret-key' }
        let(:session_key_for_redirect_uri) do
          GoogleApi::CloudPlatform::Client.session_key_for_redirect_uri(key)
        end

        before do
          allow(SecureRandom).to receive(:hex).and_return(key)
        end

        it 'has authorize_url' do
          go

          expect(assigns(:authorize_url)).to include(key)
          expect(session[session_key_for_redirect_uri]).to eq(new_project_cluster_path(project))
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

          expect(assigns(:gcp_cluster)).to be_an_instance_of(Clusters::Cluster)
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
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      it 'has new object' do
        go

        expect(assigns(:user_cluster)).to be_an_instance_of(Clusters::Cluster)
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

    def go
      get :new, namespace_id: project.namespace, project_id: project
    end
  end

  describe 'POST create for new cluster' do
    let(:params) do
      {
        cluster: {
          name: 'new-cluster',
          provider_gcp_attributes: {
            gcp_project_id: 'gcp-project-12345'
          }
        }
      }
    end

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

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

    def go
      post :create_gcp, params.merge(namespace_id: project.namespace, project_id: project)
    end
  end

  describe 'POST create for existing cluster' do
    let(:params) do
      {
        cluster: {
          name: 'new-cluster',
          platform_kubernetes_attributes: {
            api_url: 'http://my-url',
            token: 'test',
            namespace: 'aaa'
          }
        }
      }
    end

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

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

          expect(project.clusters.first).to be_user
          expect(project.clusters.first).to be_kubernetes
          expect(project.clusters.first).to be_platform_kubernetes_rbac
        end
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

    def go
      post :create_user, params.merge(namespace_id: project.namespace, project_id: project)
    end
  end

  describe 'GET status' do
    let(:cluster) { create(:cluster, :providing_by_gcp, projects: [project]) }

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

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

    def go
      get :status, namespace_id: project.namespace,
                   project_id: project,
                   id: cluster,
                   format: :json
    end
  end

  describe 'GET show' do
    let(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

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

    def go
      get :show, namespace_id: project.namespace,
                 project_id: project,
                 id: cluster
    end
  end

  describe 'PUT update' do
    context 'when cluster is provided by GCP' do
      let(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      context 'when changing parameters' do
        let(:params) do
          {
            cluster: {
              enabled: false,
              name: 'my-new-cluster-name',
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
        end

        it "does not change cluster name" do
          go

          expect(cluster.name).to eq('test-cluster')
        end

        context 'when cluster is being created' do
          let(:cluster) { create(:cluster, :providing_by_gcp, projects: [project]) }

          it "rejects changes" do
            go

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:show)
            expect(cluster.enabled).to be_truthy
          end
        end
      end
    end

    context 'when cluster is provided by user' do
      let(:cluster) { create(:cluster, :provided_by_user, projects: [project]) }
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      context 'when format is json' do
        context 'when changing parameters' do
          context 'when valid parameters are used' do
            let(:params) do
              {
                cluster: {
                  enabled: false,
                  name: 'my-new-cluster-name',
                  platform_kubernetes_attributes: {
                    namespace: 'my-namespace'
                  }
                }
              }
            end

            it "updates and redirects back to show page" do
              go_json

              cluster.reload
              expect(response).to have_http_status(:no_content)
              expect(cluster.enabled).to be_falsey
              expect(cluster.name).to eq('my-new-cluster-name')
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
              go_json

              expect(response).to have_http_status(:bad_request)
            end
          end
        end
      end

      context 'when format is html' do
        context 'when update enabled' do
          let(:params) do
            {
              cluster: {
                enabled: false,
                name: 'my-new-cluster-name',
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
            expect(cluster.platform_kubernetes.namespace).to eq('my-namespace')
          end
        end
      end
    end

    describe 'security' do
      set(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

      let(:params) do
        { cluster: { enabled: false } }
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

    def go
      put :update, params.merge(namespace_id: project.namespace,
                                project_id: project,
                                id: cluster)
    end

    def go_json
      put :update, params.merge(namespace_id: project.namespace,
                                project_id: project,
                                id: cluster,
                                format: :json)
    end
  end

  describe 'DELETE destroy' do
    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      context 'when cluster is provided by GCP' do
        context 'when cluster is created' do
          let!(:cluster) { create(:cluster, :provided_by_gcp, :production_environment, projects: [project]) }

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
      set(:cluster) { create(:cluster, :provided_by_gcp, :production_environment, projects: [project]) }

      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:maintainer).of(project) }
      it { expect { go }.to be_denied_for(:developer).of(project) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end

    def go
      delete :destroy, namespace_id: project.namespace,
                       project_id: project,
                       id: cluster
    end
  end
end

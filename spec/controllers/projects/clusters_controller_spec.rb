require 'spec_helper'

describe Projects::ClustersController do
  include AccessMatchersForController
  include GoogleApi::CloudPlatformHelpers

  describe 'GET index' do
    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_master(user)
        sign_in(user)
      end

      context 'when project has a cluster' do
        let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
        let(:project) { cluster.project }

        it { expect(go).to redirect_to(project_cluster_path(project, project.cluster)) }
      end

      context 'when project does not have a cluster' do
        let(:project) { create(:project) }

        it { expect(go).to redirect_to(new_project_cluster_path(project)) }
      end
    end

    describe 'security' do
      let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
      let(:project) { cluster.project }

      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:master).of(project) }
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

  describe 'GET login' do
    let(:project) { create(:project) }

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_master(user)
        sign_in(user)
      end

      context 'when omniauth has been configured' do
        let(:key) { 'secere-key' }

        let(:session_key_for_redirect_uri) do
          GoogleApi::CloudPlatform::Client.session_key_for_redirect_uri(key)
        end

        before do
          allow(SecureRandom).to receive(:hex).and_return(key)
        end

        it 'has authorize_url' do
          go

          expect(assigns(:authorize_url)).to include(key)
          expect(session[session_key_for_redirect_uri]).to eq(providers_gcp_new_project_clusters_url(project))
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
    end

    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:master).of(project) }
      it { expect { go }.to be_denied_for(:developer).of(project) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end

    def go
      get :login, namespace_id: project.namespace, project_id: project
    end
  end

  shared_examples 'requires to login' do
    it 'redirects to create a cluster' do
      subject

      expect(response).to redirect_to(login_project_clusters_path(project))
    end
  end

  describe 'GET new_gcp' do
    let(:project) { create(:project) }

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_master(user)
        sign_in(user)
      end

      context 'when access token is valid' do
        before do
          stub_google_api_validate_token
        end

        it 'has new object' do
          go

          expect(assigns(:cluster)).to be_an_instance_of(Clusters::Cluster)
        end
      end

      context 'when access token is expired' do
        before do
          stub_google_api_expired_token
        end

        it { expect(go).to redirect_to(login_project_clusters_path(project)) }
      end

      context 'when access token is not stored in session' do
        it { expect(go).to redirect_to(login_project_clusters_path(project)) }
      end
    end

    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:master).of(project) }
      it { expect { go }.to be_denied_for(:developer).of(project) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end

    def go
      get :new_gcp, namespace_id: project.namespace, project_id: project
    end
  end

  describe 'POST create' do
    let(:project) { create(:project) }

    let(:params) do
      {
        cluster: {
          name: 'new-cluster',
          provider_type: :gcp,
          provider_gcp_attributes: {
            gcp_project_id: '111'
          }
        }
      }
    end

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_master(user)
        sign_in(user)
      end

      context 'when access token is valid' do
        before do
          stub_google_api_validate_token
        end

        context 'when creates a cluster on gke' do
          it 'creates a new cluster' do
            expect(ClusterProvisionWorker).to receive(:perform_async)
            expect { go }.to change { Clusters::Cluster.count }
            expect(response).to redirect_to(project_cluster_path(project, project.cluster))
          end
        end
      end

      context 'when access token is expired' do
        before do
          stub_google_api_expired_token
        end

        it 'redirects to login page' do
          expect(go).to redirect_to(login_project_clusters_path(project))
        end
      end

      context 'when access token is not stored in session' do
        it 'redirects to login page' do
          expect(go).to redirect_to(login_project_clusters_path(project))
        end
      end
    end

    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:master).of(project) }
      it { expect { go }.to be_denied_for(:developer).of(project) }
      it { expect { go }.to be_denied_for(:reporter).of(project) }
      it { expect { go }.to be_denied_for(:guest).of(project) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end

    def go
      post :create, params.merge(namespace_id: project.namespace, project_id: project)
    end
  end

  describe 'GET status' do
    let(:cluster) { create(:cluster, :project, :providing_by_gcp) }
    let(:project) { cluster.project }

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_master(user)
        sign_in(user)
      end

      it "responds with matching schema" do
        go

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('cluster_status')
      end
    end

    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:master).of(project) }
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
    let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.project }

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_master(user)
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
      it { expect { go }.to be_allowed_for(:master).of(project) }
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
    let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.project }

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_master(user)
        sign_in(user)
      end

      context 'when update enabled' do
        let(:params) do
          {
            cluster: { enabled: false }
          }
        end

        it "updates and redirects back to show page" do
          go

          cluster.reload
          expect(response).to redirect_to(project_cluster_path(project, project.cluster))
          expect(flash[:notice]).to eq('Cluster was successfully updated.')
          expect(cluster.enabled).to be_falsey
        end

        context 'when cluster is being created' do
          let(:cluster) { create(:cluster, :project, :providing_by_gcp) }

          it "rejects changes" do
            go

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:show)
            expect(cluster.enabled).to be_truthy
          end
        end
      end
    end

    describe 'security' do
      let(:params) do
        {
          cluster: { enabled: false }
        }
      end

      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:master).of(project) }
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
  end

  describe 'delete update' do
    let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.project }

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_master(user)
        sign_in(user)
      end

      it "destroys and redirects back to clusters list" do
        expect { go }
          .to change { Clusters::Cluster.count }.by(-1)
          .and change { Clusters::Platforms::Kubernetes.count }.by(-1)
          .and change { Clusters::Providers::Gcp.count }.by(-1)

        expect(response).to redirect_to(project_clusters_path(project))
        expect(flash[:notice]).to eq('Cluster integration was successfully removed.')
      end

      context 'when cluster is being created' do
        let(:cluster) { create(:cluster, :project, :providing_by_gcp) }

        it "destroys and redirects back to clusters list" do
          expect { go }
            .to change { Clusters::Cluster.count }.by(-1)
            .and change { Clusters::Providers::Gcp.count }.by(-1)

          expect(response).to redirect_to(project_clusters_path(project))
          expect(flash[:notice]).to eq('Cluster integration was successfully removed.')
        end
      end

      context 'when provider is user' do
        let(:cluster) { create(:cluster, :project, :provided_by_user) }

        it "destroys and redirects back to clusters list" do
          expect { go }
            .to change { Clusters::Cluster.count }.by(-1)
            .and change { Clusters::Platforms::Kubernetes.count }.by(-1)
            .and change { Clusters::Providers::Gcp.count }.by(0)

          expect(response).to redirect_to(project_clusters_path(project))
          expect(flash[:notice]).to eq('Cluster integration was successfully removed.')
        end
      end
    end

    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(project) }
      it { expect { go }.to be_allowed_for(:master).of(project) }
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

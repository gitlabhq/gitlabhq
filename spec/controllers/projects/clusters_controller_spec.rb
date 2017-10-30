require 'spec_helper'

describe Projects::ClustersController do
  set(:user) { create(:user) }
  set(:project) { create(:project) }
  let(:role) { :master }

  before do
    project.team << [user, role]

    sign_in(user)
  end

  describe 'GET index' do
    subject do
      get :index, namespace_id: project.namespace,
                  project_id: project
    end

    context 'when cluster is already created' do
      let!(:cluster) { create(:gcp_cluster, :created_on_gke, project: project) }

      it 'redirects to show a cluster' do
        subject

        expect(response).to redirect_to(project_cluster_path(project, cluster))
      end
    end

    context 'when we do not have cluster' do
      it 'redirects to create a cluster' do
        subject

        expect(response).to redirect_to(new_project_cluster_path(project))
      end
    end
  end

  describe 'GET login' do
    render_views

    subject do
      get :login, namespace_id: project.namespace,
                  project_id: project
    end

    context 'when we do have omniauth configured' do
      it 'shows login button' do
        subject

        expect(response.body).to include('auth_buttons/signin_with_google')
      end
    end

    context 'when we do not have omniauth configured' do
      before do
        stub_omniauth_setting(providers: [])
      end

      it 'shows notice message' do
        subject

        expect(response.body).to include('Ask your GitLab administrator if you want to use this service.')
      end
    end
  end

  shared_examples 'requires to login' do
    it 'redirects to create a cluster' do
      subject

      expect(response).to redirect_to(login_project_clusters_path(project))
    end
  end

  describe 'GET new' do
    render_views

    subject do
      get :new, namespace_id: project.namespace,
                project_id: project
    end

    context 'when logged' do
      before do
        make_logged_in
      end

      it 'shows a creation form' do
        subject

        expect(response.body).to include('Create cluster')
      end
    end

    context 'when not logged' do
      it_behaves_like 'requires to login'
    end
  end

  describe 'POST create' do
    subject do
      post :create, params.merge(namespace_id: project.namespace,
                                 project_id: project)
    end

    context 'when not logged' do
      let(:params) { {} }

      it_behaves_like 'requires to login'
    end

    context 'when logged in' do
      before do
        make_logged_in
      end

      context 'when all required parameters are set' do
        let(:params) do
          {
            cluster: {
              gcp_cluster_name: 'new-cluster',
              gcp_project_id: '111'
            }
          }
        end

        before do
          expect(ClusterProvisionWorker).to receive(:perform_async) { }
        end

        it 'creates a new cluster' do
          expect { subject }.to change { Gcp::Cluster.count }

          expect(response).to redirect_to(project_cluster_path(project, project.cluster))
        end
      end

      context 'when not all required parameters are set' do
        render_views

        let(:params) do
          {
            cluster: {
              project_namespace: 'some namespace'
            }
          }
        end

        it 'shows an error message' do
          expect { subject }.not_to change { Gcp::Cluster.count }

          expect(response).to render_template(:new)
        end
      end
    end
  end

  describe 'GET status' do
    let(:cluster) { create(:gcp_cluster, :created_on_gke, project: project) }

    subject do
      get :status, namespace_id: project.namespace,
                   project_id: project,
                   id: cluster,
                   format: :json
    end

    it "responds with matching schema" do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('cluster_status')
    end
  end

  describe 'GET show' do
    render_views

    let(:cluster) { create(:gcp_cluster, :created_on_gke, project: project) }

    subject do
      get :show, namespace_id: project.namespace,
                 project_id: project,
                 id: cluster
    end

    context 'when logged as master' do
      it "allows to update cluster" do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include("Save")
      end

      it "allows remove integration" do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include("Remove integration")
      end
    end

    context 'when logged as developer' do
      let(:role) { :developer }

      it "does not allow to access page" do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PUT update' do
    render_views

    let(:service) { project.build_kubernetes_service }
    let(:cluster) { create(:gcp_cluster, :created_on_gke, project: project, service: service) }
    let(:params) { {} }

    subject do
      put :update, params.merge(namespace_id: project.namespace,
                                project_id: project,
                                id: cluster)
    end

    context 'when logged as master' do
      context 'when valid params are used' do
        let(:params) do
          {
            cluster: { enabled: false }
          }
        end

        it "redirects back to show page" do
          subject

          expect(response).to redirect_to(project_cluster_path(project, project.cluster))
          expect(flash[:notice]).to eq('Cluster was successfully updated.')
        end
      end

      context 'when invalid params are used' do
        let(:params) do
          {
            cluster: { project_namespace: 'my Namespace 321321321 #' }
          }
        end

        it "rejects changes" do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:show)
        end
      end
    end

    context 'when logged as developer' do
      let(:role) { :developer }

      it "does not allow to update cluster" do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'delete update' do
    let(:cluster) { create(:gcp_cluster, :created_on_gke, project: project) }

    subject do
      delete :destroy, namespace_id: project.namespace,
                       project_id: project,
                       id: cluster
    end

    context 'when logged as master' do
      it "redirects back to clusters list" do
        subject

        expect(response).to redirect_to(project_clusters_path(project))
        expect(flash[:notice]).to eq('Cluster integration was successfully removed.')
      end
    end

    context 'when logged as developer' do
      let(:role) { :developer }

      it "does not allow to destroy cluster" do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  def make_logged_in
    session[GoogleApi::CloudPlatform::Client.session_key_for_token] = '1234'
    session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at] = in_hour.to_i.to_s
  end

  def in_hour
    Time.now + 1.hour
  end
end

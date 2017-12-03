require 'spec_helper'

describe Projects::ClustersController do
  include AccessMatchersForController
  include GoogleApi::CloudPlatformHelpers

  set(:project) { create(:project) }

  describe 'GET index' do
    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_master(user)
        sign_in(user)
      end

      context 'when project has a cluster' do
        let!(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

        it { expect(go).to redirect_to(project_cluster_path(project, project.cluster)) }
      end

      context 'when project does not have a cluster' do
        it { expect(go).to redirect_to(new_project_cluster_path(project)) }
      end
    end

    describe 'security' do
      let(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

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

  describe 'GET status' do
    let(:cluster) { create(:cluster, :providing_by_gcp, projects: [project]) }

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
    let(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

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
    context 'Managed' do
      let(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }
      let(:user) { create(:user) }

      before do
        project.add_master(user)
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
          expect(response).to redirect_to(project_cluster_path(project, project.cluster))
          expect(flash[:notice]).to eq('Cluster was successfully updated.')
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

    context 'User' do
      let(:cluster) { create(:cluster, :provided_by_user, projects: [project]) }
      let(:user) { create(:user) }

      before do
        project.add_master(user)
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
          expect(response).to redirect_to(project_cluster_path(project, project.cluster))
          expect(flash[:notice]).to eq('Cluster was successfully updated.')
          expect(cluster.enabled).to be_falsey
          expect(cluster.name).to eq('my-new-cluster-name')
          expect(cluster.platform_kubernetes.namespace).to eq('my-namespace')
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

    describe 'security' do
      set(:cluster) { create(:cluster, :providing_by_gcp, projects: [project]) }

      let(:params) do
        { cluster: { enabled: false } }
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

  describe 'DELETE destroy' do
    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_master(user)
        sign_in(user)
      end

      context 'GCP' do
        context 'when cluster is created' do
          let!(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

          it "destroys and redirects back to clusters list" do
            expect { go }
              .to change { Clusters::Cluster.count }.by(-1)
              .and change { Clusters::Platforms::Kubernetes.count }.by(-1)
              .and change { Clusters::Providers::Gcp.count }.by(-1)

            expect(response).to redirect_to(project_clusters_path(project))
            expect(flash[:notice]).to eq('Cluster integration was successfully removed.')
          end
        end

        context 'when cluster is being created' do
          let!(:cluster) { create(:cluster, :providing_by_gcp, projects: [project]) }

          it "destroys and redirects back to clusters list" do
            expect { go }
              .to change { Clusters::Cluster.count }.by(-1)
              .and change { Clusters::Providers::Gcp.count }.by(-1)

            expect(response).to redirect_to(project_clusters_path(project))
            expect(flash[:notice]).to eq('Cluster integration was successfully removed.')
          end
        end
      end

      context 'User' do
        context 'when provider is user' do
          let!(:cluster) { create(:cluster, :provided_by_user, projects: [project]) }

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
    end

    describe 'security' do
      set(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

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

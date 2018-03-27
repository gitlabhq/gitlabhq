require 'spec_helper'

describe Projects::Clusters::UserController do
  include AccessMatchersForController

  set(:project) { create(:project) }

  describe 'GET new' do
    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_master(user)
        sign_in(user)
      end

      it 'has new object' do
        go

        expect(assigns(:cluster)).to be_an_instance_of(Clusters::Cluster)
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
      get :new, namespace_id: project.namespace, project_id: project
    end
  end

  describe 'POST create' do
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
        project.add_master(user)
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
end

# frozen_string_literal: true

require 'spec_helper'

describe Groups::ClustersController do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    group.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET index' do
    describe 'functionality' do
      context 'when project does not have a cluster' do
        it 'returns an empty state page' do
          get :index, group_id: group

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:index, partial: :empty_state)
          expect(assigns(:clusters)).to eq([])
        end
      end
    end
  end

  describe 'GET new' do
    describe 'functionality' do
      it 'has new object' do
        get :new, group_id: group

        expect(assigns(:user_cluster)).to be_an_instance_of(Clusters::Cluster)
      end
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
      context 'when creates a cluster' do
        it 'creates a new cluster' do
          expect(ClusterProvisionWorker).to receive(:perform_async)

          expect do
            post :create_user, params.merge(group_id: group)
          end.to change { Clusters::Cluster.count }.and change { Clusters::Platforms::Kubernetes.count }

          expect(response).to redirect_to(group_cluster_path(group, group.clusters.first))

          expect(group.clusters.first).to be_user
          expect(group.clusters.first).to be_kubernetes
        end
      end
    end
  end

  describe 'GET show' do
    let(:cluster) { create(:cluster, :provided_by_user, groups: [group]) }

    describe 'functionality' do
      it "renders view" do
        get :show, group_id: group, id: cluster

        expect(response).to have_gitlab_http_status(:ok)
        expect(assigns(:cluster)).to eq(cluster)
      end
    end
  end
end

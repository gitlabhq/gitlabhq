require 'spec_helper'

describe Projects::Clusters::GcpController do
  include AccessMatchersForController
  include GoogleApi::CloudPlatformHelpers

  set(:project) { create(:project) }

  describe 'POST create' do
    let(:params) do
      {
        cluster: {
          name: 'new-cluster',
          provider_gcp_attributes: {
            gcp_project_id: '111'
          }
        }
      }
    end

    before do
      allow_any_instance_of(GoogleApi::CloudPlatform::Client)
        .to receive(:projects_zones_clusters_create) do
        OpenStruct.new(
          self_link: 'projects/gcp-project-12345/zones/us-central1-a/operations/ope-123',
          status: 'RUNNING'
        )
      end
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

        it 'redirects to new clusters form' do
          puts described_class
          expect(go).to redirect_to(new_project_cluster_path(project))
        end
      end

      context 'when access token is not stored in session' do
        it 'redirects to new clusters form' do
          expect(go).to redirect_to(new_project_cluster_path(project))
        end
      end
    end

    describe 'security' do
      before do
        allow_any_instance_of(described_class)
        .to receive(:token_in_session).and_return('token')
        allow_any_instance_of(described_class)
        .to receive(:expires_at_in_session).and_return(1.hour.since.to_i.to_s)
        allow(WaitForClusterCreationWorker).to receive(:perform_in).and_return(nil)
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
      post :create, params.merge(namespace_id: project.namespace, project_id: project)
    end
  end
end

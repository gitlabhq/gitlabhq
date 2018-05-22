require 'spec_helper'

describe Projects::ClustersController do
  include AccessMatchersForController

  set(:project) { create(:project) }

  describe 'GET metrics' do
    let(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

    describe 'functionality' do
      let(:user) { create(:user) }

      before do
        project.add_master(user)
        sign_in(user)
      end

      context "Can't query Prometheus" do
        it 'returns not found' do
          go

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'can query Prometheus' do
        let(:prometheus_adapter) { double('prometheus_adapter', can_query?: true, query: nil) }

        before do
          allow(controller).to receive(:prometheus_adapter).and_return(prometheus_adapter)
        end

        it 'queries cluster metrics' do
          go

          expect(prometheus_adapter).to have_received(:query).with(:cluster)
        end

        context 'when response has content' do
          let(:query_response) { { response: nil } }

          before do
            allow(prometheus_adapter).to receive(:query).and_return(query_response)
          end

          it 'returns prometheus query response' do
            go

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.body).to eq(query_response.to_json)
          end
        end

        context 'when response has no content' do
          let(:query_response) { {} }

          before do
            allow(prometheus_adapter).to receive(:query).and_return(query_response)
          end

          it 'returns prometheus query response' do
            go

            expect(response).to have_gitlab_http_status(:no_content)
          end
        end
      end
    end

    def go
      get :metrics, format: :json,
                    namespace_id: project.namespace,
                    project_id: project,
                    id: cluster
    end

    describe 'security' do
      let(:prometheus_adapter) { double('prometheus_adapter', can_query?: true, query: nil) }
      before do
        allow(controller).to receive(:prometheus_adapter).and_return(prometheus_adapter)
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
  end
end

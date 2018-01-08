require 'spec_helper'

describe Admin::GeoNodesController, :postgresql do
  shared_examples 'unlicensed geo action' do
    it 'redirects to the license page' do
      expect(response).to redirect_to(admin_license_path)
    end

    it 'displays a flash message' do
      expect(controller).to set_flash[:alert].to('You need a different license to enable Geo replication')
    end
  end

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe '#index' do
    render_views

    def go
      get :index
    end

    context 'with add-on license available' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      end

      it 'does not display a flash message' do
        go

        expect(flash).not_to include(:alert)
      end
    end

    context 'without add-on license available' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(false)
      end

      it 'displays a flash message' do
        go

        expect(flash[:alert]).to include('You need a different license to enable Geo replication')
      end

      it 'does not redirects to the license page' do
        go
        expect(response).not_to redirect_to(admin_license_path)
      end
    end
  end

  describe '#destroy' do
    let!(:geo_node) { create(:geo_node) }

    def go
      delete(:destroy, id: geo_node)
    end

    context 'without add-on license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(false)
      end

      it 'deletes the node' do
        expect { go }.to change { GeoNode.count }.by(-1)
      end
    end

    context 'with add-on license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      end

      it 'deletes the node' do
        expect { go }.to change { GeoNode.count }.by(-1)
      end
    end
  end

  describe '#create' do
    let(:geo_node_attributes) { { url: 'http://example.com' } }

    def go
      post :create, geo_node: geo_node_attributes
    end

    context 'without add-on license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?) { false }
        go
      end

      it_behaves_like 'unlicensed geo action'
    end

    context 'with add-on license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      end

      it 'delegates the create of the Geo node to Geo::NodeCreateService' do
        expect_any_instance_of(Geo::NodeCreateService).to receive(:execute).once.and_call_original

        go
      end
    end
  end

  describe '#update' do
    let(:geo_node_attributes) { { url: 'http://example.com' } }

    let(:geo_node) { create(:geo_node) }

    def go
      post :update, id: geo_node, geo_node: geo_node_attributes
    end

    context 'without add-on license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?) { false }
        go
      end

      it_behaves_like 'unlicensed geo action'
    end

    context 'with add-on license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      end

      it 'updates the node' do
        go

        geo_node.reload
        expect(geo_node.url.chomp('/')).to eq(geo_node_attributes[:url])
      end

      it 'delegates the update of the Geo node to Geo::NodeUpdateService' do
        expect_any_instance_of(Geo::NodeUpdateService).to receive(:execute).once

        go
      end
    end
  end

  describe '#repair' do
    let(:geo_node) { create(:geo_node) }
    def go
      post :repair, id: geo_node
    end

    before do
      allow(Gitlab::Geo).to receive(:license_allows?) { false }
      go
    end

    it_behaves_like 'unlicensed geo action'
  end

  describe '#toggle' do
    context 'without add-on license' do
      let(:geo_node) { create(:geo_node) }

      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(false)
        post :toggle, id: geo_node
      end

      it_behaves_like 'unlicensed geo action'
    end

    context 'with add-on license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      end

      context 'with a primary node' do
        before do
          post :toggle, id: geo_node
        end

        let(:geo_node) { create(:geo_node, :primary, enabled: true) }

        it 'does not disable the node' do
          expect(geo_node.reload).to be_enabled
        end

        it 'displays a flash message' do
          expect(controller).to set_flash[:alert].to("Primary node can't be disabled.")
        end

        it 'redirects to the geo nodes page' do
          expect(response).to redirect_to(admin_geo_nodes_path)
        end
      end

      context 'with a secondary node' do
        let(:geo_node) { create(:geo_node, url: 'http://example.com') }

        context 'when succeed' do
          before do
            post :toggle, id: geo_node
          end

          it 'disables the node' do
            expect(geo_node.reload).not_to be_enabled
          end

          it 'displays a flash message' do
            expect(controller).to set_flash[:notice].to('Node http://example.com/ was successfully disabled.')
          end

          it 'redirects to the geo nodes page' do
            expect(response).to redirect_to(admin_geo_nodes_path)
          end
        end

        context 'when fail' do
          before do
            allow_any_instance_of(GeoNode).to receive(:toggle!).and_return(false)
            post :toggle, id: geo_node
          end

          it 'does not disable the node' do
            expect(geo_node.reload).to be_enabled
          end

          it 'displays a flash message' do
            expect(controller).to set_flash[:alert].to('There was a problem disabling node http://example.com/.')
          end

          it 'redirects to the geo nodes page' do
            expect(response).to redirect_to(admin_geo_nodes_path)
          end
        end
      end
    end
  end

  describe '#status' do
    let(:geo_node) { create(:geo_node) }

    context 'without add-on license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(false)
        get :status, id: geo_node, format: :json
      end

      it_behaves_like 'unlicensed geo action'
    end

    context 'with add-on license' do
      let(:geo_node_status) { build(:geo_node_status, :healthy, geo_node: geo_node) }

      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
        allow_any_instance_of(Geo::NodeStatusFetchService).to receive(:call).and_return(geo_node_status)
      end

      it 'returns the status' do
        get :status, id: geo_node, format: :json

        expect(response).to match_response_schema('geo_node_status')
      end
    end
  end
end

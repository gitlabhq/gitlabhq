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

      it 'renders creation form' do
        expect(go).to render_template(partial: 'admin/geo_nodes/_form')
      end
    end

    context 'without add-on license available' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(false)
      end

      it 'does not render the creation form' do
        expect(go).not_to render_template(partial: 'admin/geo_nodes/_form')
      end

      it 'displays a flash message' do
        go
        expect(controller).to set_flash.now[:alert].to('You need a different license to enable Geo replication')
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
    let(:geo_node_attributes) { { url: 'http://example.com', geo_node_key_attributes: { key: SSHKeygen.generate } } }

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

      it 'creates the node' do
        expect { go }.to change { GeoNode.count }.by(1)
      end
    end
  end

  describe '#update' do
    let(:geo_node_attributes) { { url: 'http://example.com', geo_node_key_attributes: attributes_for(:key) } }
    let(:geo_node) { create(:geo_node) }
    let!(:original_fingerprint) { geo_node.geo_node_key.fingerprint }

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
        go
      end

      it 'updates the node without changing the key' do
        geo_node.reload

        expect(geo_node.url.chomp('/')).to eq(geo_node_attributes[:url])
        expect(geo_node.geo_node_key.fingerprint).to eq(original_fingerprint)
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
          expect(controller).to set_flash.now[:alert].to("Primary node can't be disabled.")
        end

        it 'redirects to the geo nodes page' do
          expect(response).to redirect_to(admin_geo_nodes_path)
        end
      end

      context 'with a secondary node' do
        let(:geo_node) { create(:geo_node, host: 'example.com', port: 80, enabled: true) }

        context 'when succeed' do
          before do
            post :toggle, id: geo_node
          end

          it 'disables the node' do
            expect(geo_node.reload).not_to be_enabled
          end

          it 'displays a flash message' do
            expect(controller).to set_flash.now[:notice].to('Node http://example.com/ was successfully disabled.')
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
            expect(controller).to set_flash.now[:alert].to('There was a problem disabling node http://example.com/.')
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
      let(:geo_node_status) do
        GeoNodeStatus.new(
          id: 1,
          health: nil,
          attachments_count: 329,
          attachments_synced_count: 141,
          lfs_objects_count: 256,
          lfs_objects_synced_count: 123,
          repositories_count: 10,
          repositories_synced_count: 5
        )
      end

      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
        allow_any_instance_of(Geo::NodeStatusService).to receive(:call).and_return(geo_node_status)
      end

      it 'returns the status' do
        get :status, id: geo_node, format: :json

        expect(response).to match_response_schema('geo_node_status')
      end
    end
  end
end

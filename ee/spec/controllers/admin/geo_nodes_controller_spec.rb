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
end

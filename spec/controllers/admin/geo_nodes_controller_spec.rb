require 'spec_helper'

describe Admin::GeoNodesController do
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
    subject { get :index }

    context 'with add-on license available' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      end

      it 'renders creation form' do
        expect(subject).to render_template(partial: 'admin/geo_nodes/_form')
      end
    end

    context 'without add-on license available' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(false)
      end

      it 'does not render the creation form' do
        expect(subject).not_to render_template(partial: 'admin/geo_nodes/_form')
      end

      it 'displays a flash message' do
        subject
        expect(controller).to set_flash.now[:alert].to('You need a different license to enable Geo replication')
      end

      it 'does not redirects to the license page' do
        subject
        expect(response).not_to redirect_to(admin_license_path)
      end
    end
  end

  describe '#destroy' do
    let!(:geo_node) { create(:geo_node) }
    subject do
      delete(:destroy, id: geo_node)
    end

    context 'without add-on license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(false)
      end

      it 'deletes the node' do
        expect { subject }.to change { GeoNode.count }.by(-1)
      end
    end

    context 'with add-on license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      end

      it 'deletes the node' do
        expect { subject }.to change { GeoNode.count }.by(-1)
      end
    end
  end

  describe '#create' do
    let(:geo_node_attributes) { { url: 'http://example.com', geo_node_key_attributes: { key: SSHKeygen.generate } } }
    subject { post :create, geo_node: geo_node_attributes }

    context 'without add-on license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?) { false }
        subject
      end

      it_behaves_like 'unlicensed geo action'
    end

    context 'with add-on license' do
      before do
        allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
      end

      it 'creates the node' do
        expect { subject }.to change { GeoNode.count }.by(1)
      end
    end
  end

  describe '#repair' do
    let(:geo_node) { create(:geo_node) }
    subject { post :repair, id: geo_node }

    before do
      allow(Gitlab::Geo).to receive(:license_allows?) { false }
      subject
    end

    it_behaves_like 'unlicensed geo action'
  end

  describe '#backfill_repositories' do
    let(:geo_node) { create(:geo_node) }
    subject { post :backfill_repositories, id: geo_node }

    before do
      allow(Gitlab::Geo).to receive(:license_allows?) { false }
      subject
    end

    it_behaves_like 'unlicensed geo action'
  end
end

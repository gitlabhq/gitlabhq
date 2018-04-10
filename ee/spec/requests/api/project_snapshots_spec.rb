require 'spec_helper'

describe API::ProjectSnapshots do
  include ::EE::GeoHelpers

  let(:project) { create(:project) }

  describe 'GET /projects/:id/snapshot' do
    let(:primary) { create(:geo_node, :primary) }
    let(:secondary) { create(:geo_node) }

    before do
      stub_current_geo_node(primary)
    end

    it 'requests project repository raw archive from Geo primary as Geo secondary' do
      req = Gitlab::Geo::BaseRequest.new
      allow(req).to receive(:requesting_node) { secondary }

      get api("/projects/#{project.id}/snapshot", nil), {}, req.headers

      expect(response).to have_gitlab_http_status(200)
    end
  end
end

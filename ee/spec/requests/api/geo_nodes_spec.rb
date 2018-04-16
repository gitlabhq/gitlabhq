require 'spec_helper'

describe API::GeoNodes, :geo, api: true do
  include ApiHelpers
  include ::EE::GeoHelpers

  set(:primary) { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }
  set(:secondary_status) { create(:geo_node_status, :healthy, geo_node: secondary) }

  let(:unexisting_node_id) { GeoNode.maximum(:id).to_i.succ }

  set(:admin) { create(:admin) }
  set(:user) { create(:user) }

  describe 'GET /geo_nodes' do
    it 'retrieves the Geo nodes if admin is logged in' do
      get api("/geo_nodes", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/geo_nodes', dir: 'ee')
    end

    it 'denies access if not admin' do
      get api('/geo_nodes', user)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'GET /geo_nodes/:id' do
    it 'retrieves the Geo nodes if admin is logged in' do
      get api("/geo_nodes/#{primary.id}", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/geo_node', dir: 'ee')
      expect(json_response['web_edit_url']).to end_with("/admin/geo_nodes/#{primary.id}/edit")

      links = json_response['_links']
      expect(links['self']).to end_with("/api/v4/geo_nodes/#{primary.id}")
      expect(links['status']).to end_with("/api/v4/geo_nodes/#{primary.id}/status")
      expect(links['repair']).to end_with("/api/v4/geo_nodes/#{primary.id}/repair")
    end

    it_behaves_like '404 response' do
      let(:request) { get api("/geo_nodes/#{unexisting_node_id}", admin) }
    end

    it 'denies access if not admin' do
      get api('/geo_nodes', user)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'GET /geo_nodes/status' do
    it 'retrieves the Geo nodes status if admin is logged in' do
      get api("/geo_nodes/status", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/geo_node_statuses', dir: 'ee')
    end

    it 'denies access if not admin' do
      get api('/geo_nodes', user)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'GET /geo_nodes/:id/status' do
    it 'retrieves the Geo nodes status if admin is logged in' do
      stub_current_geo_node(primary)
      secondary_status.update!(version: 'secondary-version', revision: 'secondary-revision')

      expect(GeoNodeStatus).not_to receive(:current_node_status)

      get api("/geo_nodes/#{secondary.id}/status", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/geo_node_status', dir: 'ee')

      expect(json_response['version']).to eq('secondary-version')
      expect(json_response['revision']).to eq('secondary-revision')

      links = json_response['_links']

      expect(links['self']).to end_with("/api/v4/geo_nodes/#{secondary.id}/status")
      expect(links['node']).to end_with("/api/v4/geo_nodes/#{secondary.id}")
    end

    it 'fetches the current node status' do
      stub_current_geo_node(secondary)

      expect(GeoNode).to receive(:find).and_return(secondary)
      expect(GeoNodeStatus).to receive(:current_node_status).and_call_original

      get api("/geo_nodes/#{secondary.id}/status", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/geo_node_status', dir: 'ee')
    end

    it_behaves_like '404 response' do
      let(:request) { get api("/geo_nodes/#{unexisting_node_id}/status", admin) }
    end

    it 'denies access if not admin' do
      get api("/geo_nodes/#{secondary.id}/status", user)

      expect(response).to have_gitlab_http_status(403)
    end
  end

  describe 'POST /geo_nodes/:id/repair' do
    it_behaves_like '404 response' do
      let(:request) { post api("/geo_nodes/#{unexisting_node_id}/status", admin) }
    end

    it 'denies access if not admin' do
      post api("/geo_nodes/#{secondary.id}/repair", user)

      expect(response).to have_gitlab_http_status(403)
    end

    it 'returns 200 for the primary node' do
      post api("/geo_nodes/#{primary.id}/repair", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/geo_node_status', dir: 'ee')
    end

    it 'returns 200 when node does not need repairing' do
      allow_any_instance_of(GeoNode).to receive(:missing_oauth_application?).and_return(false)

      post api("/geo_nodes/#{secondary.id}/repair", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/geo_node_status', dir: 'ee')
    end

    it 'repairs a secondary with oauth application missing' do
      allow_any_instance_of(GeoNode).to receive(:missing_oauth_application?).and_return(true)

      post api("/geo_nodes/#{secondary.id}/repair", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/geo_node_status', dir: 'ee')
    end
  end

  describe 'PUT /geo_nodes/:id' do
    it_behaves_like '404 response' do
      let(:request) { put api("/geo_nodes/#{unexisting_node_id}", admin), {} }
    end

    it 'denies access if not admin' do
      put api("/geo_nodes/#{secondary.id}", user), {}

      expect(response).to have_gitlab_http_status(403)
    end

    it 'updates the parameters' do
      params = {
        enabled: false,
        url: 'https://updated.example.com/',
        files_max_capacity: 33,
        repos_max_capacity: 44
      }.stringify_keys

      put api("/geo_nodes/#{secondary.id}", admin), params

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/geo_node', dir: 'ee')
      expect(json_response).to include(params)
    end
  end

  describe 'DELETE /geo_nodes/:id' do
    it_behaves_like '404 response' do
      let(:request) { delete api("/geo_nodes/#{unexisting_node_id}", admin) }
    end

    it 'denies access if not admin' do
      delete api("/geo_nodes/#{secondary.id}", user)

      expect(response).to have_gitlab_http_status(403)
    end

    it 'deletes the node' do
      delete api("/geo_nodes/#{secondary.id}", admin)

      expect(response).to have_gitlab_http_status(204)
    end

    it 'returns 400 if Geo Node could not be deleted' do
      allow_any_instance_of(GeoNode).to receive(:destroy!).and_raise(StandardError, 'Something wrong')

      delete api("/geo_nodes/#{secondary.id}", admin)

      expect(response).to have_gitlab_http_status(500)
    end
  end

  describe 'GET /geo_nodes/current/failures/:type' do
    it 'fetches the current node failures' do
      create(:geo_project_registry, :sync_failed)
      create(:geo_project_registry, :sync_failed)

      stub_current_geo_node(secondary)
      expect(Gitlab::Geo).to receive(:current_node).and_return(secondary)

      get api("/geo_nodes/current/failures", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to match_response_schema('public_api/v4/geo_project_registry', dir: 'ee')
    end

    it 'does not show any registry when there is no failure' do
      create(:geo_project_registry, :synced)

      stub_current_geo_node(secondary)
      expect(Gitlab::Geo).to receive(:current_node).and_return(secondary)

      get api("/geo_nodes/current/failures", admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response.count).to be_zero
    end

    context 'wiki type' do
      it 'only shows wiki failures' do
        create(:geo_project_registry, :wiki_sync_failed)
        create(:geo_project_registry, :repository_sync_failed)

        stub_current_geo_node(secondary)
        expect(Gitlab::Geo).to receive(:current_node).and_return(secondary)

        get api("/geo_nodes/current/failures?type=wiki", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.count).to eq(1)
        expect(json_response.first['wiki_retry_count']).to be > 0
      end
    end

    context 'repository type' do
      it 'only shows repository failures' do
        create(:geo_project_registry, :wiki_sync_failed)
        create(:geo_project_registry, :repository_sync_failed)

        stub_current_geo_node(secondary)
        expect(Gitlab::Geo).to receive(:current_node).and_return(secondary)

        get api("/geo_nodes/current/failures?type=repository", admin)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.count).to eq(1)
        expect(json_response.first['repository_retry_count']).to be > 0
      end
    end

    context 'nonexistent type' do
      it 'returns a bad request' do
        create(:geo_project_registry, :repository_sync_failed)

        get api("/geo_nodes/current/failures?type=nonexistent", admin)

        expect(response).to have_gitlab_http_status(400)
      end
    end

    it 'denies access if not admin' do
      get api("/geo_nodes/current/failures", user)

      expect(response).to have_gitlab_http_status(403)
    end
  end
end

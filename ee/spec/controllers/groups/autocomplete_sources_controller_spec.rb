# frozen_string_literal: tru
require 'spec_helper'

describe Groups::AutocompleteSourcesController do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let!(:epic) { create(:epic, group: group) }

  before do
    group.add_developer(user)
    stub_licensed_features(epics: true)
    sign_in(user)
  end

  context '#epics' do
    it 'returns 200 status' do
      get :epics, group_id: group

      expect(response).to have_gitlab_http_status(200)
    end

    it 'returns the correct response' do
      get :epics, group_id: group

      expect(json_response).to be_an(Array)
      expect(json_response.first).to include(
        'id' => epic.id, 'iid' => epic.iid, 'title' => epic.title
      )
    end
  end

  context '#commands' do
    it 'returns 200 status' do
      get :commands, group_id: group, type: 'Epic', type_id: epic.iid

      expect(response).to have_gitlab_http_status(200)
    end

    it 'returns the correct response' do
      get :commands, group_id: group, type: 'Epic', type_id: epic.iid

      expect(json_response).to be_an(Array)
      expect(json_response).to include(
        { 'name' => 'close', 'aliases' => [], 'description' => 'Close this epic', 'params' => [] }
      )
    end
  end
end

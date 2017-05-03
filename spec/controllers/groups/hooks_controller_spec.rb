require 'spec_helper'

describe Groups::HooksController do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  describe 'POST #create' do
    it 'sets all parameters' do
      hook_params = {
        build_events: true,
        confidential_issues_events: true,
        enable_ssl_verification: true,
        issues_events: true,
        merge_requests_events: true,
        note_events: true,
        pipeline_events: true,
        push_events: true,
        tag_push_events: true,
        token: "TEST TOKEN",
        url: "http://example.com",
        wiki_page_events: true
      }

      post :create, group_id: group.to_param, hook: hook_params

      expect(response).to have_http_status(302)
      expect(group.hooks.size).to eq(1)
      expect(group.hooks.first).to have_attributes(hook_params)
    end
  end
end

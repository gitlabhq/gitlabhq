require 'spec_helper'

describe Admin::HooksController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'POST #create' do
    it 'sets all parameters' do
      hook_params = {
        enable_ssl_verification: true,
        token: "TEST TOKEN",
        url: "http://example.com",

        push_events: true,
        tag_push_events: true,
        repository_update_events: true,
        merge_requests_events: true
      }

      post :create, hook: hook_params

      expect(response).to have_gitlab_http_status(302)
      expect(SystemHook.all.size).to eq(1)
      expect(SystemHook.first).to have_attributes(hook_params)
    end
  end
end

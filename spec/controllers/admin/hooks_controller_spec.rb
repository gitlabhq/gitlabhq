# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::HooksController do
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

      post :create, params: { hook: hook_params }

      expect(response).to have_gitlab_http_status(:found)
      expect(SystemHook.all.size).to eq(1)
      expect(SystemHook.first).to have_attributes(hook_params)
    end
  end

  describe 'DELETE #destroy' do
    let!(:hook) { create(:system_hook) }
    let!(:log) { create(:web_hook_log, web_hook: hook) }
    let(:params) { { id: hook } }

    it_behaves_like 'Web hook destroyer'
  end
end

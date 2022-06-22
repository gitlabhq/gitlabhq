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
        tag_push_events: false,
        repository_update_events: true,
        merge_requests_events: false,
        url_variables: [{ key: 'token', value: 'some secret value' }]
      }

      post :create, params: { hook: hook_params }

      expect(response).to have_gitlab_http_status(:found)
      expect(SystemHook.all.size).to eq(1)
      expect(SystemHook.first).to have_attributes(hook_params.except(:url_variables))
      expect(SystemHook.first).to have_attributes(url_variables: { 'token' => 'some secret value' })
    end
  end

  describe 'POST #update' do
    let!(:hook) { create(:system_hook) }

    it 'sets all parameters' do
      hook.update!(url_variables: { 'foo' => 'bar', 'baz' => 'woo' })

      hook_params = {
        url: 'http://example.com/{baz}?token={token}',
        enable_ssl_verification: false,
        url_variables: [
          { key: 'token', value: 'some secret value' },
          { key: 'foo', value: nil }
        ]
      }

      put :update, params: { id: hook.id, hook: hook_params }

      hook.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(flash[:notice]).to include('successfully updated')
      expect(hook).to have_attributes(hook_params.except(:url_variables))
      expect(hook).to have_attributes(
        url_variables: { 'token' => 'some secret value', 'baz' => 'woo' }
      )
    end
  end

  describe 'DELETE #destroy' do
    let!(:hook) { create(:system_hook) }
    let!(:log) { create(:web_hook_log, web_hook: hook) }
    let(:params) { { id: hook } }

    it_behaves_like 'Web hook destroyer'
  end
end

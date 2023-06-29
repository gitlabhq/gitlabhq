# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::HooksController do
  let_it_be(:admin) { create(:admin) }

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
    let_it_be_with_reload(:hook) { create(:system_hook) }

    context 'with an existing token' do
      hook_params = {
        token: WebHook::SECRET_MASK,
        url: "http://example.com"
      }

      it 'does not change a token' do
        expect do
          post :update, params: { id: hook.id, hook: hook_params }
        end.not_to change { hook.reload.token }

        expect(response).to have_gitlab_http_status(:found)
        expect(flash[:alert]).to be_blank
      end
    end

    it 'sets all parameters' do
      hook.update!(url_variables: { 'foo' => 'bar', 'baz' => 'woo' })

      hook_params = {
        url: 'http://example.com/{bar}?token={token}',
        enable_ssl_verification: false,
        url_variables: [
          { key: 'token', value: 'some secret value' },
          { key: 'baz', value: nil },
          { key: 'foo', value: nil },
          { key: 'bar', value: 'qux' }
        ]
      }

      put :update, params: { id: hook.id, hook: hook_params }

      hook.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(flash[:notice]).to include('was updated')
      expect(hook).to have_attributes(hook_params.except(:url_variables))
      expect(hook).to have_attributes(
        url_variables: { 'token' => 'some secret value', 'bar' => 'qux' }
      )
    end
  end

  describe 'DELETE #destroy' do
    let_it_be(:hook) { create(:system_hook) }
    let_it_be(:log) { create(:web_hook_log, web_hook: hook) }
    let(:params) { { id: hook } }

    it_behaves_like 'Web hook destroyer'
  end
end

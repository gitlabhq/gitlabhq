# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::HooksController, feature_category: :webhooks do
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  shared_examples 'disabled on GitLab.com' do
    let(:gitlab_com?) { false }

    before do
      allow(::Gitlab).to receive(:com?) { gitlab_com? }
    end

    context 'when on GitLab.com' do
      let(:gitlab_com?) { true }

      it 'responds with a not_found status' do
        subject
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when not on GitLab.com' do
      it 'does not respond with a not_found status' do
        subject
        expect(response).not_to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #index' do
    subject(:get_index) { get :index }

    it_behaves_like 'disabled on GitLab.com'
  end

  describe 'POST #create' do
    let_it_be(:hook_params) do
      {
        enable_ssl_verification: true,
        token: 'TEST TOKEN',
        url: 'http://example.com',

        push_events: true,
        tag_push_events: false,
        repository_update_events: true,
        merge_requests_events: false,
        url_variables: [{ key: 'token', value: 'some secret value' }]
      }
    end

    subject(:post_create) { post :create, params: { hook: hook_params } }

    it 'sets all parameters' do
      post_create

      expect(response).to have_gitlab_http_status(:found)
      expect(SystemHook.all.size).to eq(1)
      expect(SystemHook.first).to have_attributes(hook_params.except(:url_variables))
      expect(SystemHook.first).to have_attributes(url_variables: { 'token' => 'some secret value' })
    end

    it_behaves_like 'disabled on GitLab.com'

    context 'with custom_webhook_template and custom_headers' do
      let_it_be(:hook_params) do
        {
          url: 'http://example.com',
          custom_webhook_template: '{"event": "test"}',
          custom_headers: [{ key: 'X-Custom-Header', value: 'secret-value' }]
        }
      end

      it 'saves custom_webhook_template and custom_headers' do
        post_create

        hook = SystemHook.first
        expect(hook.custom_webhook_template).to eq('{"event": "test"}')
        expect(hook.custom_headers).to eq({ 'X-Custom-Header' => 'secret-value' })
      end
    end
  end

  describe 'POST #update' do
    let_it_be_with_reload(:hook) { create(:system_hook) }

    let_it_be(:hook_params) do
      {
        url: 'http://example.com/{bar}?token={token}',
        enable_ssl_verification: false,
        url_variables: [
          { key: 'token', value: 'some secret value' },
          { key: 'baz', value: nil },
          { key: 'foo', value: nil },
          { key: 'bar', value: 'qux' }
        ]
      }
    end

    subject(:put_update) { put :update, params: { id: hook.id, hook: hook_params } }

    context 'with an existing token' do
      let_it_be(:hook_params) do
        {
          token: WebHook::SECRET_MASK,
          url: 'http://example.com'
        }
      end

      it 'does not change a token' do
        expect { put_update }.not_to change { hook.reload.token }

        expect(response).to have_gitlab_http_status(:found)
        expect(flash[:alert]).to be_blank
      end
    end

    context 'with signing_token', :aggregate_failures do
      let(:valid_signing_token) { "whsec_#{Base64.strict_encode64('a' * 32)}" }

      context 'when webhook_signing_token feature flag is enabled' do
        before do
          stub_feature_flags(webhook_signing_token: true)
        end

        it 'sets the signing token' do
          put :update, params: { id: hook.id, hook: { url: 'http://example.com', signing_token: valid_signing_token } }

          expect(hook.reload.signing_token).to eq(valid_signing_token)
        end

        context 'when signing_token is the secret mask' do
          let_it_be(:hook) { create(:system_hook, :signing_token) }

          it 'does not change the signing token' do
            expect do
              put :update, params: { id: hook.id, hook: { signing_token: WebHook::SECRET_MASK, url: 'http://example.com' } }
            end.not_to change { hook.reload.signing_token }
          end
        end
      end

      context 'when webhook_signing_token feature flag is disabled' do
        before do
          stub_feature_flags(webhook_signing_token: false)
        end

        it 'ignores the signing token param' do
          put :update, params: { id: hook.id, hook: { url: 'http://example.com', signing_token: valid_signing_token } }

          expect(hook.reload.signing_token).to be_nil
        end
      end
    end

    it 'sets all parameters' do
      hook.update!(url_variables: { 'foo' => 'bar', 'baz' => 'woo' })

      put_update

      hook.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(flash[:notice]).to include('updated')
      expect(hook).to have_attributes(hook_params.except(:url_variables))
      expect(hook).to have_attributes(
        url_variables: { 'token' => 'some secret value', 'bar' => 'qux' }
      )
    end

    context 'with custom_webhook_template and custom_headers' do
      let(:hook_params) do
        {
          custom_webhook_template: '{"event": "updated"}',
          custom_headers: [{ key: 'X-Custom-Header', value: 'new-secret' }]
        }
      end

      it 'updates custom_webhook_template and custom_headers' do
        put_update

        hook.reload
        expect(hook.custom_webhook_template).to eq('{"event": "updated"}')
        expect(hook.custom_headers).to eq({ 'X-Custom-Header' => 'new-secret' })
      end
    end

    it_behaves_like 'disabled on GitLab.com'
  end

  describe 'DELETE #destroy' do
    let_it_be(:hook) { create(:system_hook) }
    let_it_be(:log) { create(:web_hook_log, web_hook: hook) }
    let(:params) { { id: hook } }

    it_behaves_like 'Web hook destroyer'

    it_behaves_like 'disabled on GitLab.com' do
      subject { delete :destroy, params: params }
    end
  end
end

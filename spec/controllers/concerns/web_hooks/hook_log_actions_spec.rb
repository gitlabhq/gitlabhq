# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::HookLogActions, feature_category: :webhooks do
  controller(ApplicationController) do
    include WebHooks::HookLogActions

    attr_accessor :hook

    def after_retry_redirect_path
      '/redirect_path'
    end
  end

  let(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let(:webhook) { create(:project_hook, project: project) }
  let(:hook_log) { create(:web_hook_log, web_hook: webhook) }

  before do
    sign_in(user)
    allow(controller).to receive_messages(
      current_user: user,
      hook: webhook
    )
    allow(controller).to receive(:redirect_to)
    allow(controller).to receive(:redirect_back)

    routes.draw do
      get 'retry' => 'anonymous#retry'
    end
  end

  describe '#retry' do
    let(:resend_service) { instance_double(WebHooks::Events::ResendService) }
    let(:result) { ServiceResponse.success(payload: { http_status: 200 }) }

    before do
      allow(WebHooks::Events::ResendService).to receive(:new).and_return(resend_service)
      allow(resend_service).to receive(:execute).and_return(result)
    end

    it 'checks rate limit with correct scope' do
      expect(controller).to receive(:check_rate_limit!).with(:web_hook_event_resend, scope: [webhook.parent, user])

      get :retry, params: { id: hook_log.id }
    end

    context 'when rate limit is exceeded' do
      it 'limits the request' do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).and_return(true)

        get :retry, params: { id: hook_log.id }

        expect(response).to have_gitlab_http_status(:too_many_requests)
      end
    end
  end
end

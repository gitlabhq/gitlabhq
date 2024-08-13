# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::WebHookLogsFinder, feature_category: :webhooks do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, :repository, namespace: group) }
  let_it_be_with_reload(:web_hook) { create(:project_hook, project: project) }

  let_it_be(:log_200) { create(:web_hook_log, web_hook: web_hook) }
  let_it_be(:log_400) { create(:web_hook_log, web_hook: web_hook, response_status: 400) }
  let_it_be(:log_404) { create(:web_hook_log, web_hook: web_hook, response_status: 404) }
  let_it_be(:log_500) { create(:web_hook_log, web_hook: web_hook, response_status: 500) }
  let_it_be(:log_502) { create(:web_hook_log, web_hook: web_hook, response_status: 502) }
  let_it_be(:log_internal_error) do
    create(:web_hook_log, web_hook: web_hook, response_status: WebHookService::InternalErrorResponse::ERROR_MESSAGE)
  end

  describe "#execute" do
    context 'when unauthorized user' do
      before_all do
        project.add_developer(user)
      end

      it 'returns empty array' do
        expect(described_class.new(web_hook, user).execute).to be_blank
      end
    end

    context 'when authorized user' do
      before_all do
        project.add_owner(user)
      end

      it 'returns web hook logs in the past 7 days' do
        create(:web_hook_log, web_hook: web_hook, created_at: 8.days.ago)
        expect(described_class.new(web_hook,
          user).execute).to match_array([log_200, log_400, log_404, log_500, log_502, log_internal_error])
      end

      context 'when filter by status_code' do
        it 'returns web hook logs with status code 200' do
          expect(described_class.new(web_hook, user,
            { status: ['200'] }).execute).to match_array([log_200])
        end

        context 'when filter by status_code string' do
          it 'returns web hook logs with status code 200..299' do
            expect(described_class.new(web_hook, user,
              { status: ['successful'] }).execute).to match_array([log_200])
          end

          it 'returns web hook logs with status code 400..499' do
            expect(described_class.new(web_hook, user,
              { status: ['client_failure'] }).execute).to match_array([log_400, log_404])
          end

          it 'returns web hook logs with status code 500..599 and WebHookService::InternalErrorResponse' do
            expect(described_class.new(web_hook, user,
              { status: ['server_failure'] }).execute).to match_array([log_500, log_502, log_internal_error])
          end
        end
      end
    end
  end
end

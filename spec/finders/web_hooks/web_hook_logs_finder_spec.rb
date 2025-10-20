# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::WebHookLogsFinder, :freeze_time, feature_category: :webhooks do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, :repository, namespace: group) }
  let_it_be_with_reload(:web_hook) { create(:project_hook, project: project) }

  let_it_be(:log_200) { create(:web_hook_log, web_hook: web_hook, created_at: 10.minutes.ago) }
  let_it_be(:log_400) { create(:web_hook_log, web_hook: web_hook, response_status: 400, created_at: 1.day.ago) }
  let_it_be(:log_404) { create(:web_hook_log, web_hook: web_hook, response_status: 404, created_at: 2.days.ago) }
  let_it_be(:log_500) { create(:web_hook_log, web_hook: web_hook, response_status: 500, created_at: 3.days.ago) }
  let_it_be(:log_502) { create(:web_hook_log, web_hook: web_hook, response_status: 502, created_at: 5.days.ago) }
  let_it_be(:log_internal_error) do
    create(:web_hook_log,
      web_hook: web_hook,
      response_status: WebHookService::InternalErrorResponse::ERROR_MESSAGE,
      created_at: 6.days.ago
    )
  end

  let_it_be(:old_log) { create(:web_hook_log, web_hook: web_hook, created_at: 8.days.ago) }

  describe "#execute" do
    context 'when unauthorized user' do
      before_all do
        project.add_developer(user)
      end

      it 'returns an empty relation' do
        expect(described_class.new(web_hook, user).execute).to be_empty
      end
    end

    context 'when authorized user' do
      before_all do
        project.add_owner(user)
      end

      it 'returns web hook logs in the past 7 days' do
        expect(described_class.new(web_hook, user).execute).to match_array(
          [log_200, log_400, log_404, log_500, log_502, log_internal_error]
        )
      end

      context 'when filtering by timestamp range' do
        it 'returns web hook logs between start_time and end_time' do
          params = { start_time: 4.days.ago, end_time: 10.hours.ago }

          expect(described_class.new(web_hook, user, params).execute).to match_array([log_400, log_404, log_500])
        end

        it 'allows filtering down to the second' do
          create(:web_hook_log, web_hook: web_hook, created_at: log_200.created_at + 1.second)

          params = { start_time: log_200.created_at - 1.second, end_time: log_200.created_at }

          expect(described_class.new(web_hook, user, params).execute).to match_array([log_200])
        end

        context 'when only start_time is provided' do
          let(:params) { { start_time: 4.days.ago } }

          it 'raises an error' do
            expect { described_class.new(web_hook, user, params).execute }.to raise_error(ArgumentError)
          end
        end

        context 'when only end_time is provided' do
          let(:params) { { end_time: 10.hours.ago } }

          it 'raises an error' do
            expect { described_class.new(web_hook, user, params).execute }.to raise_error(ArgumentError)
          end
        end
      end

      context 'when filtering by status_code' do
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

      context 'when filtering by id' do
        it 'returns the web hook log with the given id' do
          expect(described_class.new(web_hook, user, { id: log_200.id }).execute).to contain_exactly(log_200)
        end

        it 'does not return logs older than 7 days' do
          expect(described_class.new(web_hook, user, { id: old_log.id }).execute).to be_empty
        end

        it 'does not return logs outside timestamp filter' do
          expect(
            described_class.new(
              web_hook, user, { id: log_200.id, start_time: 4.days.ago, end_time: 10.hours.ago }
            ).execute
          ).to be_empty
        end

        it 'does not return logs not matching status filter' do
          expect(
            described_class.new(web_hook, user, { id: old_log.id, status: ['server_failure'] }).execute
          ).to be_empty
        end
      end
    end
  end
end

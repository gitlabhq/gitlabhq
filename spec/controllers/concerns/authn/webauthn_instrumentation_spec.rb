# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::WebauthnInstrumentation, :aggregate_failures, :clean_gitlab_redis_shared_state, feature_category: :system_access do
  controller(ActionController::Base) do
    include Gitlab::InternalEventsTracking
    include Authn::WebauthnInstrumentation
  end

  describe 'constants' do
    describe 'PASSKEY_EVENT_TRACKING_STATUS' do
      it 'verifies the constant`s contents' do
        expect(described_class::PASSKEY_EVENT_TRACKING_STATUS).to match({
          0 => 'attempt',
          1 => 'success',
          2 => 'failure'
        })
      end
    end

    describe 'PASSKEY_EVENT_TRACKING_ENTRY_POINT' do
      it 'verifies the constant`s contents' do
        expect(described_class::PASSKEY_EVENT_TRACKING_ENTRY_POINT).to match({
          1 => 'two_factor_page',
          2 => 'password_page',
          3 => 'two_factor_after_login_page',
          4 => 'passwordless_passkey_button'
        })
      end
    end
  end

  describe 'track_passkey_internal_event' do
    subject(:track_passkey_internal_event) { controller.track_passkey_internal_event(**args) }

    let(:user) { create(:user, :with_passkey) }
    let(:user_agent) do
      'Mozilla/5.0 (iPhone; CPU iPhone OS 8_1_3 like Mac OS X)' \
        'AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B466 Safari/600.1.4'
    end

    let(:request) do
      rack_session = Rack::Session::SessionId.new(SecureRandom.hex(16))
      session = instance_double(ActionDispatch::TestRequest::Session, id: rack_session, '[]': {}, dig: {})
      instance_double(
        ActionDispatch::TestRequest,
        { user_agent: user_agent,
          remote_ip: '124.00.22',
          session: session }
      )
    end

    before do
      allow(controller).to receive(:request).and_return(request)
    end

    shared_examples 'does not trigger event' do
      it 'does not trigger event' do
        expect { track_passkey_internal_event }.not_to trigger_internal_events(event_name)
      end
    end

    context 'with event_name: register_passkey' do
      let(:event_name) { 'register_passkey' }
      let(:status) { 0 }
      let(:entry_point) { '2' } # String num to test the string conversion branch

      let(:args) do
        {
          user: user,
          event_name: event_name,
          status: status,
          entry_point: entry_point
        }
      end

      context 'when it tracks the internal event' do
        let(:expected_additional_props) do
          {
            status: described_class::PASSKEY_EVENT_TRACKING_STATUS[status],
            entry_point: described_class::PASSKEY_EVENT_TRACKING_ENTRY_POINT[entry_point.to_i],
            browser: 'Mobile Safari',
            device_type: 'smartphone',
            device_name: 'iPhone',
            has_2fa: 'false'
          }
        end

        let(:total_count_metric) { 'counts.count_total_passkey_registration_actions_monthly' }

        # Individual metrics
        let(:attempt_metric) do
          'redis_hll_counters.count_distinct_user_id_from_attempt_passkey_registration_weekly'
        end

        let(:password_page_metric) do
          'redis_hll_counters.count_distinct_user_id_from_password_page_passkey_registration_monthly'
        end

        let(:disabled_two_factor_metric) do
          'redis_hll_counters.count_distinct_user_id_from_disabled_two_factor_passkey_registration_weekly'
        end

        it 'triggers relevant event & increments usage metrics' do
          expect { track_passkey_internal_event }
            .to trigger_internal_events(event_name)
              .with(
                user: user, project: nil, namespace: nil, category: controller.class.name,
                additional_properties: expected_additional_props
              )
              .and increment_usage_metrics(total_count_metric)
              .and increment_usage_metrics(disabled_two_factor_metric)
              .and increment_usage_metrics(attempt_metric)
              .and increment_usage_metrics(password_page_metric)
        end
      end

      context 'when it does not track the internal event' do
        let(:status) { nil }

        it_behaves_like 'does not trigger event'
      end
    end

    context 'with event_name: authenticate_passkey' do
      let(:event_name) { 'authenticate_passkey' }
      let(:entry_point) { 4 }
      let(:status) { 0 }

      let(:args) do
        {
          user: user,
          event_name: event_name,
          status: status,
          entry_point: entry_point
        }
      end

      context 'with an unauthenticated user (passwordless sign_in attempt)' do
        context 'when it tracks the internal event' do
          let(:user) { nil }
          let(:expected_additional_props) do
            {
              status: described_class::PASSKEY_EVENT_TRACKING_STATUS[status],
              entry_point: described_class::PASSKEY_EVENT_TRACKING_ENTRY_POINT[entry_point],
              browser: 'Mobile Safari',
              device_type: 'smartphone',
              device_name: 'iPhone',
              has_2fa: nil # Will only increment the metric on true/false after user login
            }
          end

          let(:total_count_metric) { 'counts.count_total_authenticate_passkey_actions' }

          # Individual metrics
          let(:attempt_metric) do
            'counts.count_total_attempt_authenticate_passkey'
          end

          let(:passwordless_passkey_button_metric) do
            'counts.count_total_passwordless_passkey_button_auth_passkey'
          end

          let(:disabled_two_factor_metric) do
            'counts.count_total_disabled_two_factor_auth_passkey'
          end

          it 'triggers relevant event & increments usage metrics' do
            expect { track_passkey_internal_event }
              .to trigger_internal_events(event_name)
                .with(
                  user: nil, project: nil, namespace: nil, category: controller.class.name,
                  additional_properties: expected_additional_props
                )
            .and increment_usage_metrics(total_count_metric)
            .and increment_usage_metrics(attempt_metric)
            .and increment_usage_metrics(passwordless_passkey_button_metric)
            .and not_increment_usage_metrics(disabled_two_factor_metric)
          end
        end
      end

      context 'with an invalid user_agent (ad-blockers interfering with request tracking)' do
        context 'when it tracks the internal event' do
          let(:user_agent) { '' }
          let(:user) { create(:user, :two_factor) }
          let(:expected_additional_props) do
            {
              status: described_class::PASSKEY_EVENT_TRACKING_STATUS[status],
              entry_point: described_class::PASSKEY_EVENT_TRACKING_ENTRY_POINT[entry_point],
              browser: nil,
              device_type: nil,
              device_name: nil,
              has_2fa: 'true'
            }
          end

          let(:total_count_metric) { 'counts.count_total_authenticate_passkey_actions' }

          # Individual metrics
          let(:attempt_metric) do
            'counts.count_total_attempt_authenticate_passkey'
          end

          let(:passwordless_passkey_button_metric) do
            'counts.count_total_passwordless_passkey_button_auth_passkey'
          end

          let(:disabled_two_factor_metric) do
            'counts.count_total_disabled_two_factor_auth_passkey'
          end

          let(:enabled_two_factor_metric) do
            'counts.count_total_enabled_two_factor_auth_passkey_monthly'
          end

          it 'triggers relevant event & increments usage metrics' do
            expect { track_passkey_internal_event }
              .to trigger_internal_events(event_name)
                .with(
                  user: user, project: nil, namespace: nil, category: controller.class.name,
                  additional_properties: expected_additional_props
                )
            .and increment_usage_metrics(total_count_metric)
            .and increment_usage_metrics(attempt_metric)
            .and increment_usage_metrics(passwordless_passkey_button_metric)
            .and not_increment_usage_metrics(disabled_two_factor_metric)
            .and increment_usage_metrics(enabled_two_factor_metric)
          end
        end
      end

      context 'when it does not track the internal event' do
        let(:status) { nil }

        it_behaves_like 'does not trigger event'
      end
    end
  end
end

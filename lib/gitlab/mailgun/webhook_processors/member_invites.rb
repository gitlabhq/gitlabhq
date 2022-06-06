# frozen_string_literal: true

module Gitlab
  module Mailgun
    module WebhookProcessors
      class MemberInvites < Base
        ProcessWebhookServiceError = Class.new(StandardError)

        def execute
          return unless should_process?

          @member = Member.find_by_invite_token(invite_token)
          update_member_and_log if member
        rescue ProcessWebhookServiceError => e
          Gitlab::ErrorTracking.track_exception(e)
        end

        private

        attr_reader :member

        def should_process?
          payload['event'] == 'failed' && payload['severity'] == 'permanent' &&
            payload['tags']&.include?(::Members::Mailgun::INVITE_EMAIL_TAG)
        end

        def update_member_and_log
          log_update_event if member.update(invite_email_success: false)
        end

        def log_update_event
          Gitlab::AppLogger.info(
            message: "UPDATED MEMBER INVITE_EMAIL_SUCCESS: member_id: #{member.id}",
            event: 'updated_member_invite_email_success'
          )
        end

        def invite_token
          # may want to validate schema in some way using ::JSONSchemer.schema(SCHEMA_PATH).valid?(message) if this
          # gets more complex
          payload.dig('user-variables', ::Members::Mailgun::INVITE_EMAIL_TOKEN_KEY) ||
            raise(ProcessWebhookServiceError, "Expected to receive #{::Members::Mailgun::INVITE_EMAIL_TOKEN_KEY} " \
                                              "in user-variables: #{payload}")
        end
      end
    end
  end
end

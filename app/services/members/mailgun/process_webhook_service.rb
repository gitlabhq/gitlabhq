# frozen_string_literal: true

module Members
  module Mailgun
    class ProcessWebhookService
      ProcessWebhookServiceError = Class.new(StandardError)

      def initialize(payload)
        @payload = payload
      end

      def execute
        @member = Member.find_by_invite_token(invite_token)
        update_member_and_log if member
      rescue ProcessWebhookServiceError => e
        Gitlab::ErrorTracking.track_exception(e)
      end

      private

      attr_reader :payload, :member

      def update_member_and_log
        log_update_event if member.update(invite_email_success: false)
      end

      def log_update_event
        Gitlab::AppLogger.info "UPDATED MEMBER INVITE_EMAIL_SUCCESS: member_id: #{member.id}"
      end

      def invite_token
        # may want to validate schema in some way using ::JSONSchemer.schema(SCHEMA_PATH).valid?(message) if this
        # gets more complex
        payload.dig('user-variables', ::Members::Mailgun::INVITE_EMAIL_TOKEN_KEY) ||
          raise(ProcessWebhookServiceError, "Failed to receive #{::Members::Mailgun::INVITE_EMAIL_TOKEN_KEY} in user-variables: #{payload}")
      end
    end
  end
end

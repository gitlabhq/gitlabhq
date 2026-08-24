# frozen_string_literal: true

module Mailgun
  class WebhooksController < ApplicationController
    respond_to :json

    skip_before_action :authenticate_user!
    skip_before_action :verify_authenticity_token

    before_action :ensure_feature_enabled!
    before_action :authenticate_signature!

    feature_category :team_planning

    WEBHOOK_PROCESSORS = [
      Gitlab::Mailgun::WebhookProcessors::FailureLogger,
      Gitlab::Mailgun::WebhookProcessors::MemberInvites
    ].freeze

    def process_webhook
      WEBHOOK_PROCESSORS.each do |processor_class|
        processor_class.new(event_data_params).execute
      end

      head :ok
    end

    private

    def ensure_feature_enabled!
      render_406 unless Gitlab::CurrentSettings.mailgun_events_enabled?
    end

    def authenticate_signature!
      access_denied! unless valid_signature?
    end

    def valid_signature?
      return false if Gitlab::CurrentSettings.mailgun_signing_key.blank?

      # per this guide: https://documentation.mailgun.com/en/latest/user_manual.html#webhooks
      digest = OpenSSL::Digest.new('SHA256')
      data = [signature_params[:timestamp], signature_params[:token]].join

      hmac_digest = OpenSSL::HMAC.hexdigest(digest, Gitlab::CurrentSettings.mailgun_signing_key, data)

      ActiveSupport::SecurityUtils.secure_compare(signature_params[:signature], hmac_digest)
    end

    def signature_params
      params.permit(signature: [:timestamp, :token, :signature]).fetch(:signature, {})
    end

    def event_data_params
      params.permit(
        'event-data': [
          :event, :severity, :recipient, :id, :reason,
          { tags: [],
            'delivery-status': [:code, :message],
            'user-variables': [::Members::Mailgun::INVITE_EMAIL_TOKEN_KEY] }
        ]
      )['event-data']
    end

    def render_406
      # failure to stop retries per https://documentation.mailgun.com/en/latest/user_manual.html#webhooks
      head :not_acceptable
    end
  end
end

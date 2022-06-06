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
        processor_class.new(params['event-data']).execute
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
      data = [params.dig(:signature, :timestamp), params.dig(:signature, :token)].join

      hmac_digest = OpenSSL::HMAC.hexdigest(digest, Gitlab::CurrentSettings.mailgun_signing_key, data)

      ActiveSupport::SecurityUtils.secure_compare(params.dig(:signature, :signature), hmac_digest)
    end

    def render_406
      # failure to stop retries per https://documentation.mailgun.com/en/latest/user_manual.html#webhooks
      head :not_acceptable
    end
  end
end

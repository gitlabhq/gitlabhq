# frozen_string_literal: true

module RequestPayloadLogger
  extend ActiveSupport::Concern
  include Gitlab::Logging::CloudflareHelper

  def append_info_to_payload(payload)
    super

    payload[:ua] = request.env["HTTP_USER_AGENT"]
    payload[:remote_ip] = request.remote_ip
    payload[Labkit::Correlation::CorrelationId::LOG_KEY] = Labkit::Correlation::CorrelationId.current_id

    payload[:metadata] = Gitlab::ApplicationContext.current

    if defined?(urgency)
      payload[:request_urgency] = urgency&.name
      payload[:target_duration_s] = urgency&.duration
    end

    logged_user = auth_user
    if logged_user.present?
      payload[:user_id] = logged_user.try(:id)
      payload[:username] = logged_user.try(:username)
    end

    payload[:queue_duration_s] = request.env[::Gitlab::Middleware::RailsQueueDuration::GITLAB_RAILS_QUEUE_DURATION_KEY]
    payload[:response_bytes] = response.body_parts.sum(&:bytesize) if Feature.enabled?(:log_response_length)

    store_cloudflare_headers!(payload, request)
  end
end

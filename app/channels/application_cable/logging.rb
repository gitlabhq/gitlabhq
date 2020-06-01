# frozen_string_literal: true

module ApplicationCable
  module Logging
    private

    def notification_payload(_)
      super.merge!(
        Labkit::Correlation::CorrelationId::LOG_KEY => request.request_id,
        user_id: current_user&.id,
        username: current_user&.username,
        remote_ip: request.remote_ip,
        ua: request.env['HTTP_USER_AGENT']
      )
    end
  end
end

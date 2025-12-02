# frozen_string_literal: true

#
# Handles support for WebAuthn analytics instrumentation in controllers
#
module Authn
  module WebauthnInstrumentation
    extend ActiveSupport::Concern
    include Gitlab::InternalEventsTracking

    PASSKEY_EVENT_TRACKING_STATUS = {
      0 => 'attempt',
      1 => 'success',
      2 => 'failure'
    }.freeze

    PASSKEY_EVENT_TRACKING_ENTRY_POINT = {
      1 => 'two_factor_page',
      2 => 'password_page',
      3 => 'two_factor_after_login_page',
      4 => 'passwordless_passkey_button'
    }.freeze

    # Tracks a WebAuthn internal event
    #
    # Requires event_name(string), status(int)
    #
    # Optional: entry_point(int), user(object)
    #
    def track_passkey_internal_event(event_name:, status:, entry_point: nil, user: nil)
      return unless event_name && status

      entry_point = entry_point && entry_point.is_a?(String) ? entry_point.to_i : entry_point

      Gitlab::InternalEvents.track_event(
        event_name,
        user: user,
        category: self.class.name,
        additional_properties: passkey_track_event_additional_properties(
          status: PASSKEY_EVENT_TRACKING_STATUS[status],
          entry_point: PASSKEY_EVENT_TRACKING_ENTRY_POINT[entry_point],
          user: user
        )
      )
    end

    private

    def passkey_track_event_additional_properties(status: nil, entry_point: nil, user: nil)
      device_detector = Gitlab::SafeDeviceDetector.new(request.user_agent)
      {
        status: status,
        entry_point: entry_point,
        browser: device_detector.name,
        device_type: device_detector.device_type,
        device_name: device_detector.device_name,
        has_2fa: user&.two_factor_enabled?&.to_s
      }
    end
  end
end

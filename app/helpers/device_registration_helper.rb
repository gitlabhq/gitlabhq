# frozen_string_literal: true

module DeviceRegistrationHelper
  def device_registration_data(current_password_required:, target_path:, webauthn_error:)
    {
      initial_error: webauthn_error && webauthn_error[:message],
      target_path: target_path,
      password_required: current_password_required.to_s
    }
  end
end

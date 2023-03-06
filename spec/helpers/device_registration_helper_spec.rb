# frozen_string_literal: true

require "spec_helper"

RSpec.describe DeviceRegistrationHelper, feature_category: :system_access do
  describe "#device_registration_data" do
    it "returns a hash with device registration properties without initial error" do
      device_registration_data = helper.device_registration_data(
        current_password_required: false,
        target_path: "/my/path",
        webauthn_error: nil
      )

      expect(device_registration_data).to eq(
        {
          initial_error: nil,
          target_path: "/my/path",
          password_required: "false"
        })
    end

    it "returns a hash with device registration properties with initial error" do
      device_registration_data = helper.device_registration_data(
        current_password_required: true,
        target_path: "/my/path",
        webauthn_error: { message: "my error" }
      )

      expect(device_registration_data).to eq(
        {
          initial_error: "my error",
          target_path: "/my/path",
          password_required: "true"
        })
    end
  end
end

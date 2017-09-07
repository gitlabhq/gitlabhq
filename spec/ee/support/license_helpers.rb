module EE
  module LicenseHelpers
    # Enable/Disable a feature on the License for a spec.
    #
    # Example:
    #
    #   stub_licensed_features(geo: true, deploy_board: false)
    #
    # This enables `geo` and disables `deploy_board` features for a spec.
    # Other features are still enabled/disabled as defined in the licence.
    def stub_licensed_features(features)
      unknown_features = features.keys - License::FEATURE_CODES.keys
      raise "Unknown features: #{unknown_features.inspect}" unless unknown_features.empty?

      allow(License).to receive(:feature_available?).and_call_original

      features.each do |feature, enabled|
        allow(License).to receive(:feature_available?).with(feature) { enabled }
      end
    end

    def enable_namespace_license_check!
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      current_application_settings.update!(check_namespace_plan: true)
    end
  end
end

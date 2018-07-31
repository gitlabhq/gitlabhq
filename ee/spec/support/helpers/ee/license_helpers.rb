module EE
  module LicenseHelpers
    # Enable/Disable a feature on the License for a spec.
    #
    # Example:
    #
    #   stub_licensed_features(geo: true, deploy_board: false)
    #
    # This enables `geo` and disables `deploy_board` features for a spec.
    # Other features are still enabled/disabled as defined in the license.
    def stub_licensed_features(features)
      existing_features = License::FEATURES_BY_PLAN.values.flatten.map(&:to_sym)
      missing_features = features.keys.map(&:to_sym) - existing_features

      if missing_features.any?
        subject = missing_features.join(', ')
        noun = 'feature'.pluralize(missing_features.size)
        raise ArgumentError, "#{subject} should be defined as licensed #{noun}"
      end

      allow(License).to receive(:feature_available?).and_call_original

      features.each do |feature, enabled|
        allow(License).to receive(:feature_available?).with(feature) { enabled }
      end
    end

    def enable_namespace_license_check!
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
      ::Gitlab::CurrentSettings.update!(check_namespace_plan: true)
    end
  end
end

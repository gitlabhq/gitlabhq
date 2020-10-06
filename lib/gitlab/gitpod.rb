# frozen_string_literal: true

module Gitlab
  class Gitpod
    class << self
      def feature_available?
        # The gitpod_bundle feature could be conditionally applied, so check if `!off?`
        !feature.off? || feature_enabled?
      end

      def feature_enabled?(actor = nil)
        Feature.enabled?(:gitpod, actor, default_enabled: true)
      end

      def feature_and_settings_enabled?(actor = nil)
        feature_enabled?(actor) && Gitlab::CurrentSettings.gitpod_enabled
      end

      private

      def feature
        Feature.get(:gitpod) # rubocop:disable Gitlab/AvoidFeatureGet
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  class Sourcegraph
    class << self
      def feature_conditional?
        feature.conditional?
      end

      def feature_available?
        # The sourcegraph_bundle feature could be conditionally applied, so check if `!off?`
        !feature.off?
      end

      def feature_enabled?(actor = nil)
        feature.enabled?(actor)
      end

      private

      def feature
        Feature.get(:sourcegraph) # rubocop:disable Gitlab/AvoidFeatureGet
      end
    end
  end
end

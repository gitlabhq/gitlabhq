# frozen_string_literal: true

module Gitlab
  class Sourcegraph
    class << self
      def feature_conditional?
        feature.conditional?
      end

      def feature_available?
        # The sourcegraph feature could be conditionally applied, so check if `!off?`
        # We also can't just check !off? because the ActiveRecord might not exist yet
        self.feature_enabled? || !feature.off?
      end

      def feature_enabled?(actor = nil)
        # Some CI jobs grep for Feature.enabled? in our codebase, so it is important this reference stays around.
        Feature.enabled?(:sourcegraph, actor)
      end

      private

      def feature
        Feature.get(:sourcegraph) # rubocop:disable Gitlab/AvoidFeatureGet
      end
    end
  end
end

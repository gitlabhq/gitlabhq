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

      def feature_enabled?(thing = nil)
        feature.enabled?(thing)
      end

      private

      def feature
        Feature.get(:sourcegraph)
      end
    end
  end
end

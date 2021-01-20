# frozen_string_literal: true

# See Gitlab::APIAuthentication::Builder
module Gitlab
  module APIAuthentication
    class SentThroughBuilder
      def initialize(strategies, resolvers)
        @strategies = strategies
        @resolvers = resolvers
      end

      def sent_through(*locators)
        locators.each do |locator|
          @strategies[locator] |= @resolvers
        end
      end
    end
  end
end

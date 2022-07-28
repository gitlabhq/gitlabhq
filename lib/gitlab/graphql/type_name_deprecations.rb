# frozen_string_literal: true

module Gitlab
  module Graphql
    module TypeNameDeprecations
      # Contains the deprecations in place.
      # Example:
      #
      #   DEPRECATIONS = [
      #     Gitlab::Graphql::DeprecationsBase::NameDeprecation.new(
      #       old_name: 'CiRunnerUpgradeStatusType', new_name: 'CiRunnerUpgradeStatus', milestone: '15.3'
      #     )
      #   ].freeze
      DEPRECATIONS = [].freeze

      def self.map_graphql_name(name)
        name
      end

      include Gitlab::Graphql::DeprecationsBase
    end
  end
end

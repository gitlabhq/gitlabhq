# frozen_string_literal: true

module Types
  module WorkItems
    class SortEnum < ::Types::SortEnum
      graphql_name 'WorkItemSort'
      description 'Values for sorting work items'

      ::WorkItems::SortingKeys.all.each do |key, attrs| # rubocop:disable Rails/FindEach -- false positive
        description = attrs.delete(:description)
        value = attrs.fetch(:value, key)

        value key.upcase, # rubocop: disable Graphql/Descriptions -- generated dynamically
          description,
          **attrs.merge(value: value)
      end
    end
  end
end

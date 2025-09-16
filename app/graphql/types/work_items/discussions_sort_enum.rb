# frozen_string_literal: true

module Types
  module WorkItems
    class DiscussionsSortEnum < BaseEnum
      graphql_name 'WorkItemDiscussionsSort'
      description 'Values for sorting work item discussions'

      value 'CREATED_ASC', 'Created at in ascending order.', value: :created_asc
      value 'CREATED_DESC', 'Created at in descending order.', value: :created_desc

      def self.default_value
        :created_asc
      end
    end
  end
end

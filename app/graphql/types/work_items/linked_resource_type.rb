# frozen_string_literal: true

module Types
  module WorkItems
    class LinkedResourceType < BaseObject
      graphql_name 'WorkItemLinkedResource'

      authorize :read_work_item

      field :url,
        GraphQL::Types::String,
        null: false,
        description: 'URL of resource.'
    end
  end
end

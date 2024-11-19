# frozen_string_literal: true

module Types
  module WorkItems
    class DescriptionTemplateType < BaseObject
      graphql_name 'WorkItemDescriptionTemplate'

      authorize :read_work_item

      field :content, GraphQL::Types::String,
        description: 'Content of Description Template.', null: false
      field :name, GraphQL::Types::String,
        description: 'Name of Description Template.', null: false
    end
  end
end

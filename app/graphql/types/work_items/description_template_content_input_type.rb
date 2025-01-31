# frozen_string_literal: true

module Types
  module WorkItems
    class DescriptionTemplateContentInputType < BaseInputObject
      graphql_name 'WorkItemDescriptionTemplateContentInput'

      argument :name, GraphQL::Types::String,
        required: true,
        description: 'Name of the description template.'
      argument :project_id, GraphQL::Types::Int,
        required: true,
        description: 'ID of the project the template belongs to.'
    end
  end
end

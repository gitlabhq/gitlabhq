# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class DescriptionInputType < BaseInputObject
        graphql_name 'WorkItemWidgetDescriptionInput'

        argument :description, GraphQL::Types::String,
          required: true,
          description: copy_field_description(Types::WorkItemType, :description)
      end
    end
  end
end

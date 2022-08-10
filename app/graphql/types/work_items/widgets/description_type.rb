# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes
      class DescriptionType < BaseObject
        graphql_name 'WorkItemWidgetDescription'
        description 'Represents a description widget'

        implements Types::WorkItems::WidgetInterface

        field :description, GraphQL::Types::String,
          null: true,
          description: 'Description of the work item.'

        markdown_field :description_html, null: true do |resolved_object|
          resolved_object.work_item
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end

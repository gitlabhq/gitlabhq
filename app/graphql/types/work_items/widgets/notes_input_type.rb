# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class NotesInputType < BaseInputObject
        graphql_name 'WorkItemWidgetNotesInput'

        argument :discussion_locked, GraphQL::Types::Boolean,
          required: true,
          description: 'Discussion lock attribute for notes widget of the work item.'
      end
    end
  end
end

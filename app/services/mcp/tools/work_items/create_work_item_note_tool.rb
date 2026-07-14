# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class CreateWorkItemNoteTool < BaseTool
        register_version VERSIONS[:v0_1_0], {
          operation_name: 'createNote',
          graphql_operation: load_graphql('work_items/create_note.mutation.graphql')
        }

        def build_variables
          validate_no_quick_actions!(params[:body], field_name: 'note body')

          work_item_id = resolve_work_item_id

          { input: build_note_input(work_item_id) }
        end

        private

        def build_note_input(work_item_id)
          {
            noteableId: work_item_id,
            body: params[:body],
            internal: params[:internal],
            discussionId: params[:discussion_id]
          }.compact
        end
      end
    end
  end
end

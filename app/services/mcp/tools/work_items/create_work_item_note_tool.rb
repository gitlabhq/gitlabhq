# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class CreateWorkItemNoteTool < BaseTool
        class << self
          def build_mutation
            <<~GRAPHQL
              mutation CreateNote($input: CreateNoteInput!) {
                createNote(input: $input) {
                  note {
                    id
                    body
                    internal
                    createdAt
                    updatedAt
                    author {
                      id
                      name
                      username
                      avatarUrl
                      webUrl
                    }
                    discussion {
                      id
                    }
                  }
                  errors
                }
              }
            GRAPHQL
          end
        end

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'createNote',
          graphql_operation: build_mutation
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

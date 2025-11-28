# frozen_string_literal: true

module Mcp
  module Tools
    module WorkItems
      class GraphqlCreateWorkItemNoteService < GraphqlService
        register_version '0.1.0', {
          description: 'Create a new note (comment) on a GitLab work item',
          input_schema: {
            type: 'object',
            properties: {
              # Work item identification (one set required)
              url: {
                type: 'string',
                description: 'GitLab URL for the work item (e.g., https://gitlab.com/namespace/project/-/work_items/42)'
              },
              group_id: {
                type: 'string',
                description: 'ID or path of the group. Required if URL and project_path are not provided.'
              },
              project_id: {
                type: 'string',
                description: 'ID or path of the project. Required if URL and group_id are not provided.'
              },
              work_item_iid: {
                type: 'integer',
                description: 'Internal ID of the work item. Required if URL is not provided.'
              },

              # Required field
              body: {
                type: 'string',
                description: 'Content of the note/comment (max 1,048,576 characters)',
                maxLength: 1_048_576
              },

              # Optional fields
              internal: {
                type: 'boolean',
                description: 'Mark note as internal (visible only to project members with Reporter role or higher)',
                default: false
              },
              discussion_id: {
                type: 'string',
                description: 'Global ID of the discussion to reply to (format: gid://gitlab/Discussion/<id>)'
              }
            },
            required: ['body']
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::WorkItems::CreateWorkItemNoteTool
        end

        def perform_0_1_0(arguments)
          execute_graphql_tool(arguments)
        end

        override :perform_default
        def perform_default(arguments = {})
          perform_0_1_0(arguments)
        end
      end
    end
  end
end

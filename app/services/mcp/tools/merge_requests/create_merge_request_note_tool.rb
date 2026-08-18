# frozen_string_literal: true

module Mcp
  module Tools
    module MergeRequests
      class CreateMergeRequestNoteTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ContentValidation
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::MergeRequestResolution

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'createNote',
          graphql_operation: load_graphql('merge_requests/create_note.mutation.graphql')
        }

        def build_variables
          validate_no_quick_actions!(params[:body], field_name: 'note body')

          merge_request_id = resolve_merge_request!(params).to_global_id.to_s

          { input: build_note_input(merge_request_id) }
        end

        private

        def build_note_input(merge_request_id)
          {
            noteableId: merge_request_id,
            body: params[:body],
            discussionId: params[:discussion_id]
          }.compact
        end
      end
    end
  end
end

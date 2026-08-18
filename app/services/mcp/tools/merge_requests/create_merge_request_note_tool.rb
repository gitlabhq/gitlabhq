# frozen_string_literal: true

module Mcp
  module Tools
    module MergeRequests
      class CreateMergeRequestNoteTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ContentValidation
        include Mcp::Tools::Concerns::ResourceFinder

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'createNote',
          graphql_operation: load_graphql('merge_requests/create_note.mutation.graphql')
        }

        def build_variables
          validate_no_quick_actions!(params[:body], field_name: 'note body')

          merge_request_id = resolve_merge_request_id

          { input: build_note_input(merge_request_id) }
        end

        private

        def resolve_merge_request_id
          if params[:url].present?
            match = ::MergeRequest.link_reference_pattern.match(params[:url])
            raise ArgumentError, "Invalid merge request URL: #{params[:url]}" unless match

            project = find_project!("#{match[:namespace]}/#{match[:project]}")
            iid = match[:merge_request].to_i
          else
            iid = params[:merge_request_iid]
            unless iid && params[:project_id].present?
              raise ArgumentError, 'Provide either url, or project_id and merge_request_iid'
            end

            project = find_project!(params[:project_id])
          end

          merge_request = ::MergeRequestsFinder.new(
            current_user,
            project_id: project.id,
            iids: [iid]
          ).execute.first

          unless merge_request
            raise ArgumentError, 'Merge request not found: it does not exist or you do not have access to it.'
          end

          merge_request.to_global_id.to_s
        end

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

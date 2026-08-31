# frozen_string_literal: true

module Mcp
  module Tools
    module Notes
      class SaveNoteTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ContentValidation
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::UrlParser
        include Mcp::Tools::Concerns::MergeRequestResolution

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'createNote',
          graphql_operation: load_graphql('notes/create_note.mutation.graphql')
        }

        def build_variables
          validate_no_quick_actions!(params[:body], field_name: 'note body')

          { input: build_note_input }
        end

        private

        def build_note_input
          {
            noteableId: resolve_noteable_id,
            body: params[:body],
            internal: params[:internal],
            discussionId: params[:discussion_id]
          }.compact
        end

        def resolve_noteable_id
          return resolve_noteable_from_url(params[:url]) if params[:url]

          if params[:merge_request_iid] && params[:work_item_iid]
            raise ArgumentError, 'Provide only one of merge_request_iid or work_item_iid'
          elsif params[:merge_request_iid]
            resolve_merge_request!(params).to_global_id.to_s
          elsif params[:work_item_iid]
            resolve_work_item_from_params
          else
            raise ArgumentError,
              'Provide url, or merge_request_iid with project_id, or work_item_iid with project_id or group_id'
          end
        end

        def resolve_noteable_from_url(url)
          return resolve_merge_request!(params).to_global_id.to_s if ::MergeRequest.link_reference_pattern.match(url)

          unless extract_path_from_url(url).match?(WORK_ITEM_URL_PATTERN)
            raise ArgumentError, 'URL must be a merge request URL (.../-/merge_requests/<iid>) or a work item ' \
              'URL (.../-/work_items/<iid>). For issues, pass project_id and work_item_iid instead'
          end

          resolve_work_item_from_url(url)
        end

        def resolve_work_item_from_params
          parent_type = params[:project_id].presence ? :project : :group
          identifier = params[:project_id].presence || params[:group_id].presence
          raise ArgumentError, 'Provide project_id or group_id with work_item_iid' unless identifier

          parent = find_parent_by_id_or_path!(parent_type, identifier)
          find_work_item_in_parent!(parent, params[:work_item_iid]).to_global_id.to_s
        end
      end
    end
  end
end

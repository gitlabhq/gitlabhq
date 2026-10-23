# frozen_string_literal: true

module Mcp
  module Tools
    module Notes
      class SaveNoteTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ContentValidation
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::UrlParser
        include Mcp::Tools::Concerns::MergeRequestResolution

        CREATE_NOTE_QUERY = load_graphql('notes/create_note.mutation.graphql')
        # discussionToggleResolve is noteable-agnostic, so the merge request operation is reused as-is.
        TOGGLE_RESOLVE_QUERY = load_graphql('merge_requests/discussion_toggle_resolve.mutation.graphql')

        register_version VERSIONS[:v0_1_0], {}

        def graphql_operation
          resolve_discussion? ? TOGGLE_RESOLVE_QUERY : CREATE_NOTE_QUERY
        end

        def operation_name
          resolve_discussion? ? 'discussionToggleResolve' : 'createNote'
        end

        def build_variables
          return build_resolve_variables if resolve_discussion?

          validate_no_quick_actions!(params[:body], field_name: 'note body')

          { input: build_note_input }
        end

        private

        def resolve_discussion?
          params[:method] == 'resolve_discussion'
        end

        def build_resolve_variables
          { input: { id: discussion_global_id, resolve: params[:resolved] } }
        end

        def build_note_input
          {
            noteableId: resolve_noteable_id,
            body: params[:body],
            internal: params[:internal],
            discussionId: (discussion_global_id if params[:discussion_id].present?)
          }.compact
        end

        def discussion_global_id
          raw = params[:discussion_id].to_s
          return raw if raw.start_with?('gid://')

          ::Gitlab::GlobalId.build(model_name: 'Discussion', id: raw).to_s
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

          return resolve_work_item_from_url(url) if extract_path_from_url(url).match?(WORK_ITEM_URL_PATTERN)

          raise ArgumentError, 'URL must be a merge request URL (.../-/merge_requests/<iid>), a work item URL ' \
            '(.../-/work_items/<iid>), an issue URL (.../-/issues/<iid>, project-scoped), or an epic URL ' \
            '(.../groups/<full_path>/-/epics/<iid>, group-scoped)'
        end

        def resolve_work_item_from_params
          parent_type = params[:project_id].presence ? :project : :group
          identifier = params[:project_id].presence || params[:group_id].presence
          raise ArgumentError, 'Provide project_id or group_id with work_item_iid' unless identifier

          parent = find_parent_by_id_or_path!(parent_type, identifier)
          find_work_item_in_parent!(parent, params[:work_item_iid]).to_global_id.to_s
        end

        def process_result(result)
          processed_result = super
          return processed_result if processed_result[:isError] || !resolve_discussion?

          discussion = processed_result[:structuredContent]['discussion']

          structured_content = {
            'method' => 'resolve_discussion',
            'discussion_id' => discussion['id'],
            'resolved' => discussion['resolved'],
            'web_url' => discussion.dig('notes', 'nodes', 0, 'url')
          }

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(structured_content) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, structured_content)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Mcp
  module Tools
    module MergeRequests
      class SaveMergeRequestReviewTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ContentValidation
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::MergeRequestResolution

        CREATE_NOTE_QUERY = load_graphql('merge_requests/create_note.mutation.graphql')
        CREATE_DIFF_NOTE_QUERY = load_graphql('merge_requests/create_diff_note.mutation.graphql')
        TOGGLE_RESOLVE_QUERY = load_graphql('merge_requests/discussion_toggle_resolve.mutation.graphql')

        register_version VERSIONS[:v0_1_0], {}

        def graphql_operation
          case params[:method]
          when 'create_diff_note' then CREATE_DIFF_NOTE_QUERY
          when 'resolve_discussion' then TOGGLE_RESOLVE_QUERY
          else CREATE_NOTE_QUERY
          end
        end

        def operation_name
          case params[:method]
          when 'create_diff_note' then 'createDiffNote'
          when 'resolve_discussion' then 'discussionToggleResolve'
          else 'createNote'
          end
        end

        def build_variables
          case params[:method]
          when 'create_note'
            validate_no_quick_actions!(params[:body], field_name: 'note body')
            { input: {
              noteableId: noteable_global_id,
              body: params[:body],
              internal: params[:internal]
            }.compact }
          when 'reply_discussion'
            validate_no_quick_actions!(params[:body], field_name: 'note body')
            { input: {
              noteableId: noteable_global_id,
              body: params[:body],
              discussionId: discussion_global_id
            } }
          when 'create_diff_note'
            validate_no_quick_actions!(params[:body], field_name: 'note body')
            { input: {
              noteableId: noteable_global_id,
              body: params[:body],
              position: build_position
            } }
          when 'resolve_discussion'
            raise ArgumentError, 'resolved is required for resolve_discussion' if params[:resolved].nil?

            { input: { id: discussion_global_id, resolve: params[:resolved] } }
          else
            raise ArgumentError, "Unsupported method: #{params[:method]}"
          end
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        private

        def merge_request
          @merge_request ||= resolve_merge_request!(params)
        end

        # submit_review passes pre-resolved values so the per-comment fan-out
        # doesn't re-run finders and authorization for every note.
        def noteable_global_id
          params[:noteable_gid].presence || merge_request.to_global_id.to_s
        end

        def discussion_global_id
          raw = params[:discussion_id].to_s
          raise ArgumentError, 'discussion_id is required for this method' if raw.blank?
          return raw if raw.start_with?('gid://')

          ::Gitlab::GlobalId.build(model_name: 'Discussion', id: raw).to_s
        end

        def build_position
          if params[:old_path].blank? && params[:new_path].blank?
            raise ArgumentError, 'Provide old_path and/or new_path for create_diff_note'
          end

          if params[:old_line].blank? && params[:new_line].blank?
            raise ArgumentError, 'Provide old_line and/or new_line for create_diff_note'
          end

          position_shas.merge(
            paths: { oldPath: params[:old_path], newPath: params[:new_path] }.compact,
            oldLine: params[:old_line],
            newLine: params[:new_line]
          ).compact
        end

        def position_shas
          if params[:diff_head_sha].present?
            { headSha: params[:diff_head_sha], startSha: params[:diff_start_sha], baseSha: params[:diff_base_sha] }
          else
            unless merge_request.has_complete_diff_refs?
              raise ArgumentError, 'Cannot create a diff note: the merge request diff is not ready or is missing'
            end

            diff_refs = merge_request.diff_refs
            { headSha: diff_refs.head_sha, startSha: diff_refs.start_sha, baseSha: diff_refs.base_sha }
          end
        end

        def process_result(result)
          processed_result = super
          return processed_result if processed_result[:isError]

          structured_content =
            if params[:method] == 'resolve_discussion'
              resolve_discussion_output(processed_result[:structuredContent])
            else
              note_output(processed_result[:structuredContent])
            end

          return ::Mcp::Tools::Base::Response.error('Operation returned no data') unless structured_content

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(structured_content) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, structured_content)
        end

        def note_output(data)
          note = data&.dig('note')
          return unless note

          {
            'method' => params[:method],
            'note_id' => model_id(note['id']),
            'discussion_id' => note.dig('discussion', 'id'),
            'web_url' => note['url']
          }
        end

        def resolve_discussion_output(data)
          discussion = data&.dig('discussion')
          return unless discussion

          {
            'method' => params[:method],
            'discussion_id' => discussion['id'],
            'resolved' => discussion['resolved'],
            'web_url' => discussion.dig('notes', 'nodes', 0, 'url')
          }
        end

        def model_id(global_id)
          GlobalID.parse(global_id)&.model_id&.to_i
        end
      end
    end
  end
end

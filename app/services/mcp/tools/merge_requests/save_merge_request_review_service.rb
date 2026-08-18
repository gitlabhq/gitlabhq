# frozen_string_literal: true

module Mcp
  module Tools
    module MergeRequests
      class SaveMergeRequestReviewService < Base::GraphqlService
        include Mcp::Tools::Concerns::ContentValidation
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::MergeRequestResolution

        IDENTIFICATION_PARAMS = %i[url project_id merge_request_iid].freeze

        METHOD_PARAMS = {
          'create_note' => { required: %i[body], optional: %i[internal] },
          'reply_discussion' => { required: %i[body discussion_id], optional: [] },
          'create_diff_note' => { required: %i[body], optional: %i[old_path new_path old_line new_line] },
          'resolve_discussion' => { required: %i[discussion_id resolved], optional: [] },
          'submit_review' => { required: %i[comments], optional: %i[verdict summary summary_internal] },
          'post_duo_review' => { required: [], optional: [] }
        }.freeze

        MAX_REVIEW_COMMENTS = 20

        register_version '0.1.0', {
          description: 'Write merge request review artifacts as the authenticated user. ' \
            'Exactly one method per call: create_note adds a top-level comment; reply_discussion ' \
            'replies within an existing discussion; create_diff_note comments on a specific diff line; ' \
            'resolve_discussion resolves or unresolves a discussion; submit_review posts multiple diff ' \
            'comments plus an optional summary in one call; post_duo_review asks GitLab Duo to review ' \
            'the merge request. Identify the merge request by url, or by project_id and ' \
            'merge_request_iid. Each parameter below names the methods that use it.',
          annotations: {
            readOnlyHint: false,
            destructiveHint: false
          },
          input_schema: {
            type: 'object',
            properties: {
              url: {
                type: 'string',
                description: 'GitLab URL of the merge request. Provide this, or project_id and merge_request_iid.'
              },
              project_id: {
                type: 'string',
                description: 'ID or path of the project. Required if url is not provided.'
              },
              merge_request_iid: {
                type: 'integer',
                description: 'Internal ID of the merge request. Required if url is not provided.'
              },
              method: {
                type: 'string',
                enum: %w[create_note reply_discussion create_diff_note resolve_discussion
                  submit_review post_duo_review],
                description: 'The write operation to perform. Fill only the parameters listed for the ' \
                  'chosen method; other parameters are rejected.'
              },
              body: {
                type: 'string',
                description: 'Note text (create_note, reply_discussion, create_diff_note; max 1,048,576 ' \
                  'characters). Lines that begin with "/" are rejected to avoid triggering quick actions ' \
                  'such as /merge.',
                maxLength: 1_048_576
              },
              discussion_id: {
                type: 'string',
                description: 'Discussion to act on (reply_discussion, resolve_discussion). Accepts the ' \
                  'global ID (gid://gitlab/Discussion/<id>) or the bare <id> returned by ' \
                  'get_merge_request with include: ["discussions"].'
              },
              internal: {
                type: 'boolean',
                description: 'Mark the note as internal, visible only to users who can see internal ' \
                  'notes (create_note). Default is false.'
              },
              resolved: {
                type: 'boolean',
                description: 'true resolves the discussion, false unresolves it (resolve_discussion).'
              },
              old_path: {
                type: 'string',
                description: 'File path before the change (create_diff_note). Provide old_path and/or ' \
                  'new_path; for a file that was not renamed, use the same path for both.'
              },
              new_path: {
                type: 'string',
                description: 'File path after the change (create_diff_note).'
              },
              old_line: {
                type: 'integer',
                description: 'Line number in the old version of the file (create_diff_note). Use for ' \
                  'deleted or unchanged lines. Provide old_line and/or new_line.'
              },
              new_line: {
                type: 'integer',
                description: 'Line number in the new version of the file (create_diff_note). Use for ' \
                  'added or unchanged lines.'
              },
              comments: {
                type: 'array',
                description: "Diff comments to post (submit_review; 1-#{MAX_REVIEW_COMMENTS} entries). " \
                  'Each entry becomes one diff note.',
                maxItems: MAX_REVIEW_COMMENTS,
                items: {
                  type: 'object',
                  properties: {
                    file: {
                      type: 'string',
                      description: 'Path of the file to comment on, as it appears after the change. ' \
                        'For a file renamed in the diff, use the create_diff_note method with ' \
                        'old_path and new_path instead.'
                    },
                    old_line: {
                      type: 'integer',
                      description: 'Line number in the old version of the file. Provide old_line and/or new_line.'
                    },
                    new_line: {
                      type: 'integer',
                      description: 'Line number in the new version of the file.'
                    },
                    body: {
                      type: 'string',
                      description: 'Comment text for this line.'
                    },
                    suggestion: {
                      type: 'string',
                      description: 'Replacement code for the commented line, appended to the comment as ' \
                        'a suggestion block the author can apply with one click.'
                    }
                  },
                  required: %w[file body],
                  additionalProperties: false
                }
              },
              verdict: {
                type: 'string',
                description: 'Overall review verdict, prefixed to the summary note (submit_review).'
              },
              summary: {
                type: 'string',
                description: 'Summary note posted after the diff comments (submit_review). When both ' \
                  'summary and verdict are omitted, only the diff comments are posted.'
              },
              summary_internal: {
                type: 'boolean',
                description: 'Mark the summary note as internal (submit_review). Default is false.'
              }
            },
            required: %w[method]
          }
        }

        protected

        def graphql_tool_class
          Mcp::Tools::MergeRequests::SaveMergeRequestReviewTool
        end

        def perform_v0_1_0(arguments)
          validate_method_arguments!(arguments)

          case arguments[:method]
          when 'submit_review'
            perform_submit_review(arguments)
          when 'post_duo_review'
            perform_post_duo_review(arguments)
          else
            execute_graphql_tool(arguments)
          end
        end

        override :perform_default
        def perform_default(arguments = {})
          perform_v0_1_0(arguments)
        end

        # Overridden in EE, where GitLab Duo Code Review is available.
        def perform_post_duo_review(_arguments)
          raise ArgumentError, 'post_duo_review requires GitLab Duo Code Review, ' \
            'which is not available on this GitLab instance'
        end

        private

        def validate_method_arguments!(arguments)
          method = arguments[:method]
          rules = METHOD_PARAMS[method]
          raise ArgumentError, "method must be one of: #{METHOD_PARAMS.keys.join(', ')}" unless rules

          missing = rules[:required].select { |key| arguments[key].nil? }
          raise ArgumentError, "Missing required parameters for #{method}: #{missing.join(', ')}" if missing.any?

          allowed = IDENTIFICATION_PARAMS + [:method] + rules[:required] + rules[:optional]
          extra = arguments.keys.map(&:to_sym) - allowed
          return if extra.none?

          raise ArgumentError, "Parameters not valid for method '#{method}': #{extra.join(', ')}"
        end

        def perform_submit_review(arguments)
          comments = Array(arguments[:comments]).map(&:symbolize_keys)
          raise ArgumentError, 'comments must contain at least one entry' if comments.empty?

          validate_review_comments!(comments)

          # Resolve once and pass the results through the fan-out, so N comments
          # don't re-run the project/MR finders and authorization N times.
          merge_request = resolve_merge_request!(arguments)

          unless merge_request.has_complete_diff_refs?
            raise ArgumentError, 'Cannot submit a review: the merge request diff is not ready or is missing'
          end

          resolved = resolved_arguments(arguments, merge_request)
          created_notes = []
          failure = nil

          comments.each_with_index do |comment, index|
            result = execute_review_step(diff_note_arguments(resolved, comment))

            if result[:isError]
              failure = submit_review_failure(result, created_notes, index)
              break
            end

            created_notes << result[:structuredContent]
          end

          return failure if failure

          summary_note = post_summary_note(arguments, resolved)
          return submit_review_failure(summary_note, created_notes, nil) if summary_note && summary_note[:isError]

          structured_content = {
            'method' => 'submit_review',
            'comments_created' => created_notes.length,
            'notes' => created_notes,
            'summary' => summary_note&.dig(:structuredContent)
          }.compact

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(structured_content) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, structured_content)
        end

        # An invalid comment anywhere in the batch must fail the whole call before
        # any note is posted; a mid-loop failure would leave the earlier notes behind.
        def validate_review_comments!(comments)
          comments.each_with_index do |comment, index|
            validate_no_quick_actions!(comment[:body], field_name: "comments[#{index}] body")
            next if comment[:old_line].present? || comment[:new_line].present?

            raise ArgumentError, "comments[#{index}]: Provide old_line and/or new_line"
          end
        end

        def resolved_arguments(arguments, merge_request)
          diff_refs = merge_request.diff_refs

          arguments.slice(*IDENTIFICATION_PARAMS).merge(
            noteable_gid: merge_request.to_global_id.to_s,
            diff_head_sha: diff_refs.head_sha,
            diff_start_sha: diff_refs.start_sha,
            diff_base_sha: diff_refs.base_sha
          ).compact
        end

        def diff_note_arguments(resolved, comment)
          body = comment[:body].to_s
          body += "\n\n```suggestion:-0+0\n#{comment[:suggestion]}\n```" if comment[:suggestion].present?

          resolved.merge(
            method: 'create_diff_note',
            body: body,
            old_path: comment[:file],
            new_path: comment[:file],
            old_line: comment[:old_line],
            new_line: comment[:new_line]
          ).compact
        end

        # Safety net for raises the pre-validation didn't anticipate: convert them
        # to error responses so the failure path still reports the created notes.
        def execute_review_step(arguments)
          execute_graphql_tool(arguments)
        rescue ArgumentError => e
          ::Mcp::Tools::Base::Response.error(e.message)
        end

        def post_summary_note(arguments, resolved)
          return if arguments[:summary].blank? && arguments[:verdict].blank?

          body = [
            arguments[:verdict].presence && "**Review verdict:** #{arguments[:verdict]}",
            arguments[:summary]
          ].compact.join("\n\n")

          execute_review_step(
            resolved.merge(
              method: 'create_note',
              body: body,
              internal: arguments[:summary_internal]
            ).compact
          )
        end

        # The fan-out is not atomic: notes created before a failure stay posted, so the
        # error names them to let the caller resume instead of double-posting.
        def submit_review_failure(failed_result, created_notes, failed_index)
          failed_step = failed_index ? "comments[#{failed_index}]" : 'the summary note'
          error_text = failed_result[:content]&.first&.dig(:text) || 'unknown error'
          created_ids = created_notes.filter_map { |note| note['note_id'] }

          message = "submit_review failed at #{failed_step}: #{error_text}"
          message += " Notes already created (not rolled back): #{created_ids.join(', ')}." if created_ids.any?

          ::Mcp::Tools::Base::Response.error(message, { 'created_notes' => created_notes })
        end
      end
    end
  end
end

Mcp::Tools::MergeRequests::SaveMergeRequestReviewService.prepend_mod

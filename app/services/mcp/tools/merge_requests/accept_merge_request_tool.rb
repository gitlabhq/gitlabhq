# frozen_string_literal: true

module Mcp
  module Tools
    module MergeRequests
      class AcceptMergeRequestTool < Mcp::Tools::Base::GraphqlTool
        include Mcp::Tools::Concerns::ResourceFinder
        include Mcp::Tools::Concerns::MergeRequestResolution

        register_version VERSIONS[:v0_1_0], {
          operation_name: 'mergeRequestAccept',
          graphql_operation: load_graphql('merge_requests/accept_merge_request.mutation.graphql')
        }

        def execute
          return accept_response('already_merged') if merge_request.merged?

          super
        end

        def build_variables
          {
            input: {
              projectPath: merge_request.project.full_path,
              iid: merge_request.iid.to_s,
              sha: params[:sha],
              strategy: params[:strategy]&.upcase,
              # The mutation defaults squash to false and persists it, flipping squash-enabled MRs off.
              squash: params.key?(:squash) ? params[:squash] : merge_request.squash,
              commitMessage: params[:commit_message],
              squashCommitMessage: params[:squash_commit_message],
              shouldRemoveSourceBranch: params[:should_remove_source_branch]
            }.compact
          }
        end

        protected

        def build_variables_v0_1_0
          build_variables
        end

        private

        def merge_request
          @merge_request ||= resolve_merge_request!(params)
        end

        def process_result(result)
          payload_errors = result['errors'].blank? ? result.dig('data', operation_name, 'errors') : nil

          if payload_errors.present?
            if params[:strategy].present? &&
                payload_errors.include?(::Mutations::MergeRequests::Accept::ALREADY_SCHEDULED)
              # The mutation checks the standing schedule before the sha, so guard the sha here.
              return stale_scheduled_sha_error unless params[:sha] == merge_request.diff_head_sha

              return accept_response('already_scheduled')
            end

            return ::Mcp::Tools::Base::Response.error(enriched_error_message(payload_errors))
          end

          processed = super
          return processed if processed[:isError]

          status = params[:strategy].present? ? 'auto_merge_scheduled' : 'merging'
          accept_response(status, processed[:structuredContent]['mergeRequest'])
        end

        def enriched_error_message(errors)
          message = errors.join(', ')

          if params[:strategy].present? && errors.include?(::Mutations::MergeRequests::Accept::MERGE_FAILED)
            message += '. The requested auto-merge strategy may not be available for this merge request ' \
              '(for example, nothing is pending that would defer the merge). Omit strategy to merge immediately.'
          end

          message
        end

        def stale_scheduled_sha_error
          ::Mcp::Tools::Base::Response.error(
            'The merge request is already scheduled to be merged, but its head no longer matches ' \
              'the provided sha. Pass the current diff_head_sha from get_merge_request to confirm ' \
              'the armed auto-merge.'
          )
        end

        def accept_response(status, merge_request_data = nil)
          armed_strategy = merge_request_data&.dig('autoMergeStrategy') || merge_request.auto_merge_strategy

          structured_content = {
            'status' => status,
            'merge_request_url' => merge_request_data&.dig('webUrl') || ::Gitlab::UrlBuilder.build(merge_request),
            'auto_merge_strategy' => armed_strategy&.downcase
          }.compact

          formatted_content = [{ type: 'text', text: Gitlab::Json.dump(structured_content) }]
          ::Mcp::Tools::Base::Response.success(formatted_content, structured_content)
        end
      end
    end
  end
end

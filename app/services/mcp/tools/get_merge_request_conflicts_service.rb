# frozen_string_literal: true

module Mcp
  module Tools
    class GetMergeRequestConflictsService < CustomService
      # Register version with schema definition
      register_version '0.1.0', {
        description: 'Get merge conflict content for a merge request that cannot be merged. ' \
          'Returns raw git conflict markers (<<<<<<, =======, >>>>>>>) exactly as they appear in conflicted files.',
        input_schema: {
          type: 'object',
          properties: {
            project_id: {
              type: 'string',
              description: 'Project ID (numeric) or full path (e.g., "gitlab-org/gitlab")'
            },
            merge_request_iid: {
              type: 'integer',
              description: 'Merge request internal ID'
            }
          },
          required: %w[project_id merge_request_iid],
          additionalProperties: false
        },
        annotations: {
          readOnlyHint: true
        }
      }

      # Override authorization to match controller behavior
      # Uses same check as MergeRequests::Conflicts::ListService#can_be_resolved_by?
      def authorize!(params)
        # Validate project exists first for better error messages
        proj = project(params[:arguments])
        raise ArgumentError, "#{name}: project not found or inaccessible" if proj.nil?

        mr = merge_request(params[:arguments])
        raise ArgumentError, "#{name}: merge request not found" if mr.nil?
        raise ArgumentError, "#{name}: source project not found" unless mr.source_project

        access = ::Gitlab::UserAccess.new(current_user, container: mr.source_project)
        allowed = access.can_push_to_branch?(mr.source_branch)
        return if allowed

        raise Gitlab::Access::AccessDeniedError, "User #{current_user.id} does not have permission to " \
          "push to branch '#{mr.source_branch}' in project #{mr.source_project.id}"
      end

      protected

      # Main implementation - returns raw git conflict content
      def perform_0_1_0(arguments)
        mr = merge_request(arguments)
        return ::Mcp::Tools::Response.error('Merge request not found') if mr.nil?

        # Check merge status and return appropriate error
        case mr.merge_status
        when 'unchecked', 'checking', 'preparing', 'cannot_be_merged_recheck', 'cannot_be_merged_rechecking'
          return ::Mcp::Tools::Response.error(
            "Merge request merge status is '#{mr.merge_status}' — " \
              "conflicts cannot be determined until mergeability has been checked"
          )
        when 'can_be_merged'
          return ::Mcp::Tools::Response.error('Merge request does not have conflicts')
        end

        # Check if branches/refs are valid
        unless mr.has_complete_diff_refs? && !mr.branch_missing?
          return ::Mcp::Tools::Response.error('Cannot retrieve conflicts: missing branches or diff refs')
        end

        # Get raw conflict content
        conflict_list_service = MergeRequests::Conflicts::ListService.new(mr)

        # Build conflict text with file markers
        conflict_text = conflict_list_service.conflicts.files.map do |file|
          # Defensive check: content should never be nil, but guard against unexpected states
          content = file.content || ""

          # File marker with both paths (for renames) followed by raw git conflict content
          if file.their_path == file.our_path
            "# File: #{file.our_path}\n#{content}"
          else
            "# File: #{file.their_path} -> #{file.our_path}\n#{content}"
          end
        end.join("\n\n")

        # Return as plain text (no JSON structure in structuredContent)
        formatted_content = [{ type: 'text', text: conflict_text }]
        ::Mcp::Tools::Response.success(formatted_content)
      end

      private

      def project(arguments)
        @project ||= find_project(arguments['project_id'])
      end

      def merge_request(arguments)
        @merge_request ||= {}
        cache_key = "#{arguments['project_id']}_#{arguments['merge_request_iid']}"
        @merge_request[cache_key] ||= find_merge_request(arguments)
      end

      def find_merge_request(arguments)
        proj = project(arguments)
        proj.merge_requests.find_by_iid(arguments['merge_request_iid'])
      end
    end
  end
end

# frozen_string_literal: true

module MergeRequests
  module Conflicts
    class ResolveService < MergeRequests::Conflicts::BaseService
      REASON_NO_PUSH_ACCESS = :no_push_access
      REASON_NOT_RESOLVABLE_IN_UI = :not_resolvable_in_ui
      REASON_ALREADY_RESOLVED = :already_resolved
      REASON_FILE_NOT_IN_CONFLICT = :file_not_in_conflict
      REASON_INCOMPLETE_FILE = :incomplete_file
      REASON_RESOLUTION_ERROR = :resolution_error
      REASON_PRE_RECEIVE = :pre_receive

      # Commits the conflict resolution to the source branch.
      #
      # @param current_user [User]
      # @param params [Hash] as posted by the conflicts UI
      # @option params [String] :commit_message
      # @option params [Array<Hash>] :files one hash per conflicted file, with `:old_path` and `:new_path`
      #   matching a listed conflict, and either `:sections` (section ID => `'head'` or `'origin'`)
      #   or `:content` (the whole resolved file)
      # @return [ServiceResponse] on error, `reason` is one of the `REASON_` constants
      def execute(current_user, params)
        unless list_service.can_be_resolved_by?(current_user)
          return error(_('Cannot push to source branch'), REASON_NO_PUSH_ACCESS)
        end

        # The already-resolved check below is unreachable, because can_be_resolved_in_ui? is false for a
        # mergeable merge request: https://gitlab.com/gitlab-org/gitlab/-/work_items/630905
        unless list_service.can_be_resolved_in_ui?
          return error(not_resolvable_in_ui_message, REASON_NOT_RESOLVABLE_IN_UI)
        end

        files = Array.wrap(params[:files])
        invalid_files = invalid_files_error(files)
        return invalid_files if invalid_files

        Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter.track_resolve_conflict_action(user: current_user)

        if merge_request.can_be_merged?
          return error(_('The merge conflicts for this merge request have already been resolved.'),
            REASON_ALREADY_RESOLVED)
        end

        list_service.conflicts.resolve(current_user, params[:commit_message].presence, files)

        ServiceResponse.success(payload: { merge_request: merge_request })
      rescue Gitlab::Git::Conflict::Resolver::ResolutionError => e
        error(e.message, REASON_RESOLUTION_ERROR)
      rescue Gitlab::Git::PreReceiveError => e
        error(e.message, REASON_PRE_RECEIVE)
      rescue Gitlab::Git::Conflict::Resolver::ConflictSideMissing
        # A tree-conflict-tolerant lister can cache can_be_resolved_in_ui? as true for a listing that raises here.
        error(not_resolvable_in_ui_message, REASON_NOT_RESOLVABLE_IN_UI)
      end

      private

      def list_service
        @list_service ||= ListService.new(merge_request)
      end

      # Gitaly turns an unknown path or malformed sections into an internal error and an empty hash into an empty file.
      def invalid_files_error(files)
        files.each do |file|
          path = file[:new_path].presence || file[:old_path]

          unless list_service.file_for_path(file[:old_path], file[:new_path])
            return error(format(_('File %{path} is not in conflict.'), path: path), REASON_FILE_NOT_IN_CONFLICT)
          end

          if file[:content].nil? && !sections?(file[:sections])
            return error(format(_('File %{path} needs either sections or content.'), path: path),
              REASON_INCOMPLETE_FILE)
          end
        end

        nil
      end

      def sections?(sections)
        sections.respond_to?(:each_pair) && sections.present? && sections.values.all?(String)
      end

      def not_resolvable_in_ui_message
        _('The merge conflicts for this merge request cannot be resolved through GitLab. ' \
          'Please try to resolve them locally.')
      end

      def error(message, reason)
        ServiceResponse.error(message: message, reason: reason)
      end
    end
  end
end

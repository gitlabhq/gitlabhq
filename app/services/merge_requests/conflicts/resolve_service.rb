# frozen_string_literal: true

module MergeRequests
  module Conflicts
    class ResolveService < MergeRequests::Conflicts::BaseService
      REASON_NO_PUSH_ACCESS = :no_push_access
      REASON_NOT_RESOLVABLE_IN_UI = :not_resolvable_in_ui
      REASON_ALREADY_RESOLVED = :already_resolved
      REASON_MERGEABILITY_UNCHECKED = :mergeability_unchecked
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
        files = Array.wrap(params[:files])

        refusal = refusal_before_resolving(current_user, files)
        return refusal if refusal

        Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter.track_resolve_conflict_action(user: current_user)

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

      # can_be_resolved_in_ui? is false while already resolved or still checking,
      # so those go first to get their own reasons
      def refusal_before_resolving(current_user, files)
        no_push_access_error(current_user) ||
          already_resolved_error ||
          mergeability_unchecked_error ||
          not_resolvable_in_ui_error ||
          invalid_files_error(files)
      end

      def no_push_access_error(current_user)
        return if list_service.can_be_resolved_by?(current_user)

        error(_('Cannot push to source branch'), REASON_NO_PUSH_ACCESS)
      end

      def already_resolved_error
        return unless merge_request.can_be_merged?

        error(_('The merge conflicts for this merge request have already been resolved.'), REASON_ALREADY_RESOLVED)
      end

      def mergeability_unchecked_error
        return if merge_request.cannot_be_merged?

        # A push leaves the check to the next reader, so without this a retry would never get past here
        merge_request.check_mergeability(async: true)

        error(_('The mergeability of this merge request is still being checked. Please try again in a moment.'),
          REASON_MERGEABILITY_UNCHECKED)
      end

      def not_resolvable_in_ui_error
        return if list_service.can_be_resolved_in_ui?

        error(not_resolvable_in_ui_message, REASON_NOT_RESOLVABLE_IN_UI)
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

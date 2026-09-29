# frozen_string_literal: true

module MergeRequests
  module Conflicts
    class ResolveService < MergeRequests::Conflicts::BaseService
      REASON_NO_PUSH_ACCESS = :no_push_access
      REASON_NOT_RESOLVABLE_IN_UI = :not_resolvable_in_ui
      REASON_ALREADY_RESOLVED = :already_resolved
      REASON_RESOLUTION_ERROR = :resolution_error
      REASON_PRE_RECEIVE = :pre_receive

      # Commits the conflict resolution to the source branch.
      #
      # @param current_user [User]
      # @param params [Hash] `:commit_message` and `:files`, as posted by the conflicts UI
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

        Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter.track_resolve_conflict_action(user: current_user)

        if merge_request.can_be_merged?
          return error(_('The merge conflicts for this merge request have already been resolved.'),
            REASON_ALREADY_RESOLVED)
        end

        list_service.conflicts.resolve(current_user, params[:commit_message], params[:files])

        ServiceResponse.success(payload: { merge_request: merge_request })
      rescue Gitlab::Git::Conflict::Resolver::ResolutionError => e
        error(e.message, REASON_RESOLUTION_ERROR)
      rescue Gitlab::Git::PreReceiveError => e
        error(e.message, REASON_PRE_RECEIVE)
      end

      private

      def list_service
        @list_service ||= ListService.new(merge_request)
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

# frozen_string_literal: true

module Issues
  class BaseService < ::IssuableBaseService
    extend ::Gitlab::Utils::Override
    include IncidentManagement::UsageData
    include IssueTypeHelpers

    def hook_data(issue, action, old_associations: {})
      hook_data = issue.to_hook_data(current_user, old_associations: old_associations)
      hook_data[:object_attributes][:action] = action

      hook_data
    end

    def reopen_service
      Issues::ReopenService
    end

    def close_service
      Issues::CloseService
    end

    NO_REBALANCING_NEEDED = ((RelativePositioning::MIN_POSITION * 0.9999)..(RelativePositioning::MAX_POSITION * 0.9999)).freeze

    def rebalance_if_needed(issue)
      return unless issue
      return if issue.relative_position.nil?
      return if NO_REBALANCING_NEEDED.cover?(issue.relative_position)

      Issues::RebalancingWorker.perform_async(nil, *issue.project.self_or_root_group_ids)
    end

    private

    # overriding this because IssuableBaseService#constructor_container_arg returns { project: value }
    # Issues::ReopenService constructor signature is different now, it takes container instead of project also
    # IssuableBaseService#change_state dynamically picks one of the `Issues::ReopenService`, `Epics::ReopenService` or
    # MergeRequests::ReopenService, so we need this method to return { }container: value } for Issues::ReopenService
    def self.constructor_container_arg(value)
      { container: value }
    end

    def find_work_item_type_id(issue_type)
      work_item_type = WorkItems::Type.default_by_type(issue_type)
      work_item_type ||= WorkItems::Type.default_issue_type

      work_item_type.id
    end

    def filter_params(issue)
      super

      params.delete(:issue_type) unless create_issue_type_allowed?(issue, params[:issue_type])

      if params[:work_item_type].present? && !create_issue_type_allowed?(project, params[:work_item_type].base_type)
        params.delete(:work_item_type)
      end

      moved_issue = params.delete(:moved_issue)

      # Setting created_at, updated_at and iid is allowed only for admins and owners or
      # when moving an issue as we preserve the original issue attributes except id and iid.
      params.delete(:iid) unless current_user.can?(:set_issue_iid, project)
      params.delete(:created_at) unless moved_issue || current_user.can?(:set_issue_created_at, project)
      params.delete(:updated_at) unless moved_issue || current_user.can?(:set_issue_updated_at, project)

      # Only users with permission to handle error data can add it to issues
      params.delete(:sentry_issue_attributes) unless current_user.can?(:update_sentry_issue, project)

      issue.system_note_timestamp = params[:created_at] || params[:updated_at]
    end

    override :handle_move_between_ids
    def handle_move_between_ids(issue)
      issue.check_repositioning_allowed! if params[:move_between_ids]

      super

      rebalance_if_needed(issue)
    end

    def handle_escalation_status_change(issue)
      return unless issue.supports_escalation?

      if issue.escalation_status
        ::IncidentManagement::IssuableEscalationStatuses::AfterUpdateService.new(
          issue,
          current_user
        ).execute
      else
        ::IncidentManagement::IssuableEscalationStatuses::CreateService.new(issue).execute
      end
    end

    def issuable_for_positioning(id, positioning_scope)
      return unless id

      positioning_scope.find(id)
    end

    def create_assignee_note(issue, old_assignees)
      SystemNoteService.change_issuable_assignees(
        issue, issue.project, current_user, old_assignees)
    end

    def execute_hooks(issue, action = 'open', old_associations: {})
      issue_data  = Gitlab::Lazy.new { hook_data(issue, action, old_associations: old_associations) }
      hooks_scope = issue.confidential? ? :confidential_issue_hooks : :issue_hooks
      issue.namespace.execute_hooks(issue_data, hooks_scope)
      issue.namespace.execute_integrations(issue_data, hooks_scope)

      execute_incident_hooks(issue, issue_data) if issue.work_item_type&.incident?
    end

    # We can remove this code after proposal in
    # https://gitlab.com/gitlab-org/gitlab/-/issues/367550#proposal is updated.
    def execute_incident_hooks(issue, issue_data)
      issue_data[:object_kind] = 'incident'
      issue_data[:event_type] = 'incident'
      issue.namespace.execute_integrations(issue_data, :incident_hooks)
    end

    def update_project_counter_caches?(issue)
      super || issue.confidential_changed?
    end
  end
end

Issues::BaseService.prepend_mod_with('Issues::BaseService')

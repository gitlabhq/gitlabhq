# frozen_string_literal: true

module IssueLinks
  class DestroyService < IssuableLinks::DestroyService
    include IncidentManagement::UsageData

    def success(...)
      GraphqlTriggers.work_item_updated(@source)
      super
    end

    private

    def permission_to_remove_relation?
      can?(current_user, :admin_issue_link, source) && can?(current_user, :admin_issue_link, target)
    end

    def track_event
      track_incident_action(current_user, target, :incident_unrelate)
    end
  end
end

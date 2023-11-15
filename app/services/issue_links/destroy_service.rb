# frozen_string_literal: true

module IssueLinks
  class DestroyService < IssuableLinks::DestroyService
    include IncidentManagement::UsageData
    include Gitlab::Utils::StrongMemoize

    private

    def permission_to_remove_relation?
      (can?(current_user, :admin_issue_link, link.source) && can?(current_user, :create_issue_link, link.target)) ||
        (can?(current_user, :admin_issue_link, link.target) && can?(current_user, :create_issue_link, link.source))
    end

    def track_event
      track_incident_action(current_user, target, :incident_unrelate)
    end
  end
end

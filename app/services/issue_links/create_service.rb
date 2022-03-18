# frozen_string_literal: true

module IssueLinks
  class CreateService < IssuableLinks::CreateService
    def linkable_issuables(issues)
      @linkable_issuables ||= begin
        issues.select { |issue| can?(current_user, :admin_issue_link, issue) }
      end
    end

    def previous_related_issuables
      @related_issues ||= issuable.related_issues(current_user).to_a
    end

    private

    def track_event
      track_incident_action(current_user, issuable, :incident_relate)
    end

    def link_class
      IssueLink
    end
  end
end

IssueLinks::CreateService.prepend_mod_with('IssueLinks::CreateService')

# frozen_string_literal: true

module IssueLinks
  class CreateService < IssuableLinks::CreateService
    include IncidentManagement::UsageData

    def success(...)
      GraphqlTriggers.work_item_updated(issuable)
      super
    end

    def linkable_issuables(issues)
      @linkable_issuables ||= issues.select { |issue| can?(current_user, :admin_issue_link, issue) }
    end

    def previous_related_issuables
      @related_issues ||= issuable.related_issues(authorize: false).to_a
    end

    private

    def readonly_issuables(issuables)
      @readonly_issuables ||= issuables.select { |issuable| issuable.readable_by?(current_user) }
    end

    def track_event
      track_incident_action(current_user, issuable, :incident_relate)
    end

    def link_class
      IssueLink
    end

    def issuables_no_permission_error_message
      _("Couldn't link issues. You must have at least the Guest role in both projects.")
    end

    def extractor_context
      { group: issuable.namespace }
    end
  end
end

IssueLinks::CreateService.prepend_mod_with('IssueLinks::CreateService')

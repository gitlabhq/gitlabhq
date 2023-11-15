# frozen_string_literal: true

module IssueLinks
  class CreateService < IssuableLinks::CreateService
    include IncidentManagement::UsageData

    def execute
      return error(issue_no_permission_error_message, 403) unless can?(current_user, :admin_issue_link, issuable) ||
        can?(current_user, :create_issue_link, issuable)

      super
    end

    def linkable_issuables(issues)
      @linkable_issuables ||= issues.select do |issue|
        can_create_destroy_issue_link?(issue)
      end
    end

    def previous_related_issuables
      @related_issues ||= issuable.related_issues(authorize: false).to_a
    end

    private

    # A user can create/destroy an issue link if they can
    # admin the links for one issue AND create links for the other
    def can_create_destroy_issue_link?(issue)
      (can_admin_issue_link?(issuable) && can_create_issue_link?(issue)) ||
        (can_admin_issue_link?(issue) && can_create_issue_link?(issuable))
    end

    def can_admin_issue_link?(issue)
      Ability.allowed?(current_user, :admin_issue_link, issue)
    end

    def can_create_issue_link?(issue)
      Ability.allowed?(current_user, :create_issue_link, issue)
    end

    def readonly_issuables(issuables)
      @readonly_issuables ||= issuables.select { |issuable| issuable.readable_by?(current_user) }
    end

    def track_event
      track_incident_action(current_user, issuable, :incident_relate)
    end

    def link_class
      IssueLink
    end

    def issue_no_permission_error_message
      _("Couldn't link issues. You must have at least the Guest role in the source issue's project.")
    end
  end
end

IssueLinks::CreateService.prepend_mod_with('IssueLinks::CreateService')

# frozen_string_literal: true

module IssueLinks
  class CreateService < IssuableLinks::CreateService
    # rubocop: disable CodeReuse/ActiveRecord
    def relate_issuables(referenced_issue)
      link = IssueLink.find_or_initialize_by(source: issuable, target: referenced_issue)

      set_link_type(link)

      if link.changed? && link.save
        create_notes(referenced_issue)
      end

      link
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def linkable_issuables(issues)
      @linkable_issuables ||= begin
        issues.select { |issue| can?(current_user, :admin_issue_link, issue) }
      end
    end

    def create_notes(referenced_issue)
      SystemNoteService.relate_issue(issuable, referenced_issue, current_user)
      SystemNoteService.relate_issue(referenced_issue, issuable, current_user)
    end

    def previous_related_issuables
      @related_issues ||= issuable.related_issues(current_user).to_a
    end

    private

    def set_link_type(_link)
      # EE only
    end

    def track_event
      track_incident_action(current_user, issuable, :incident_relate)
    end
  end
end

IssueLinks::CreateService.prepend_mod_with('IssueLinks::CreateService')

# frozen_string_literal: true

module Issues
  class AfterCreateService < Issues::BaseService
    def execute(issue)
      todo_service.new_issue(issue, current_user)
      delete_milestone_total_issue_counter_cache(issue.milestone)
      track_incident_action(current_user, issue, :incident_created)
    end
  end
end

Issues::AfterCreateService.prepend_mod

# frozen_string_literal: true

module Issues
  class AfterCreateService < Issues::BaseService
    # TODO: this is to be removed once we get to rename the IssuableBaseService project param to container
    def initialize(container:, current_user: nil, params: {})
      super(project: container, current_user: current_user, params: params)
    end

    def execute(issue)
      todo_service.new_issue(issue, current_user)
      delete_milestone_total_issue_counter_cache(issue.milestone)
      track_incident_action(current_user, issue, :incident_created)
    end
  end
end

Issues::AfterCreateService.prepend_mod

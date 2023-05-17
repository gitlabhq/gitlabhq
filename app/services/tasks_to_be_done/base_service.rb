# frozen_string_literal: true

module TasksToBeDone
  class BaseService < ::BaseContainerService
    LABEL_PREFIX = 'tasks to be done'

    def initialize(container:, current_user:, assignee_ids: [])
      params = {
        assignee_ids: assignee_ids,
        title: title,
        description: description,
        add_labels: label_name
      }
      super(container: container, current_user: current_user, params: params)
    end

    def execute
      if (issue = existing_task_issue)
        update_service = Issues::UpdateService.new(container: project, current_user: current_user, params: { add_assignee_ids: params[:assignee_ids] })
        update_service.execute(issue)
      else
        create_service = Issues::CreateService.new(container: project, current_user: current_user, params: params, spam_params: nil)
        create_service.execute
      end
    end

    private

    def existing_task_issue
      IssuesFinder.new(
        current_user,
        project_id: project.id,
        state: 'opened',
        non_archived: true,
        label_name: label_name
      ).execute.last
    end

    def title
      raise NotImplementedError
    end

    def description
      raise NotImplementedError
    end

    def label_suffix
      raise NotImplementedError
    end

    def label_name
      "#{LABEL_PREFIX}:#{label_suffix}"
    end
  end
end

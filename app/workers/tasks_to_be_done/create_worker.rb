# frozen_string_literal: true

module TasksToBeDone
  class CreateWorker
    include ApplicationWorker

    data_consistency :always
    idempotent!
    feature_category :onboarding
    urgency :low
    worker_resource_boundary :cpu

    def perform(member_task_id, current_user_id, assignee_ids = [])
      member_task = MemberTask.find(member_task_id)
      current_user = User.find(current_user_id)
      project = member_task.project

      member_task.tasks_to_be_done.each do |task|
        service_class(task)
          .new(container: project, current_user: current_user, assignee_ids: assignee_ids)
          .execute
      end
    end

    private

    def service_class(task)
      "TasksToBeDone::Create#{task.to_s.camelize}TaskService".constantize
    end
  end
end

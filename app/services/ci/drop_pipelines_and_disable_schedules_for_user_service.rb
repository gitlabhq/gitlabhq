# frozen_string_literal: true

module Ci
  class DropPipelinesAndDisableSchedulesForUserService
    def execute(user, reason: :user_blocked, include_owned_projects_and_groups: false)
      if include_owned_projects_and_groups
        # Projects in the user namespace
        Project.personal(user).each_batch do |relation|
          project_ids = relation.pluck_primary_key

          drop_pipelines_for_projects(user, project_ids, reason)
          disable_schedules_for_projects(project_ids)
        end

        # Projects in group and descendant namespaces owned by the user
        user.owned_groups.select(:id, :traversal_ids).each_batch do |owned_groups_relation|
          owned_groups_relation.each do |owned_group|
            Project.in_namespace(owned_group.self_and_descendant_ids).each_batch do |project_relation|
              project_ids = project_relation.pluck_primary_key

              drop_pipelines_for_projects(user, project_ids, reason)
              disable_schedules_for_projects(project_ids)
            end
          end
        end
      end

      drop_pipelines_for_user(user, reason)
      disable_schedules_for_user(user)
    end

    private

    def drop_pipelines_for_user(user, reason)
      Ci::DropPipelineService.new.execute_async_for_all(
        Ci::Pipeline.for_user(user),
        reason,
        user
      )
    end

    def drop_pipelines_for_projects(user, project_ids, reason)
      Ci::DropPipelineService.new.execute_async_for_all(
        Ci::Pipeline.for_project(project_ids),
        reason,
        user
      )
    end

    def disable_schedules_for_user(user)
      Ci::PipelineSchedule.owned_by(user).active.each_batch do |relation|
        relation.update_all(active: false)
      end
    end

    def disable_schedules_for_projects(project_ids)
      Ci::PipelineSchedule.for_project(project_ids).active.each_batch do |relation|
        relation.update_all(active: false)
      end
    end
  end
end

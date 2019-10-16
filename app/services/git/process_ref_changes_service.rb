# frozen_string_literal: true

module Git
  class ProcessRefChangesService < BaseService
    PIPELINE_PROCESS_LIMIT = 4

    def execute
      changes = params[:changes]

      process_changes_by_action(:branch, changes.branch_changes)
      process_changes_by_action(:tag, changes.tag_changes)
    end

    private

    def process_changes_by_action(ref_type, changes)
      changes_by_action = group_changes_by_action(changes)

      changes_by_action.each do |_, changes|
        process_changes(ref_type, changes, execute_project_hooks: execute_project_hooks?(changes)) if changes.any?
      end
    end

    def group_changes_by_action(changes)
      changes.group_by do |change|
        change_action(change)
      end
    end

    def change_action(change)
      return :created if Gitlab::Git.blank_ref?(change[:oldrev])
      return :removed if Gitlab::Git.blank_ref?(change[:newrev])

      :pushed
    end

    def execute_project_hooks?(changes)
      (changes.size <= Gitlab::CurrentSettings.push_event_hooks_limit) || Feature.enabled?(:git_push_execute_all_project_hooks, project)
    end

    def process_changes(ref_type, changes, execute_project_hooks:)
      push_service_class = push_service_class_for(ref_type)

      changes.each do |change|
        push_service_class.new(
          project,
          current_user,
          change: change,
          push_options: params[:push_options],
          create_pipelines: change[:index] < PIPELINE_PROCESS_LIMIT || Feature.enabled?(:git_push_create_all_pipelines, project),
          execute_project_hooks: execute_project_hooks
        ).execute
      end
    end

    def push_service_class_for(ref_type)
      return Git::TagPushService if ref_type == :tag

      Git::BranchPushService
    end
  end
end

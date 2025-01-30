# frozen_string_literal: true

module Git
  class ProcessRefChangesService < BaseService
    PIPELINE_PROCESS_LIMIT = 4

    def execute
      changes = params[:changes]

      process_changes_by_action(:branch, changes.branch_changes)
      process_changes_by_action(:tag, changes.tag_changes)
      warn_if_over_process_limit(changes.branch_changes + changes.tag_changes)

      perform_housekeeping
    end

    private

    def process_changes_by_action(ref_type, changes)
      changes_by_action = group_changes_by_action(changes)

      changes_by_action.each do |action, changes|
        process_changes(ref_type, action, changes, execute_project_hooks: execute_project_hooks?(changes)) if changes.any?
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
      changes.size <= Gitlab::CurrentSettings.push_event_hooks_limit
    end

    def process_changes(ref_type, action, changes, execute_project_hooks:)
      push_service_class = push_service_class_for(ref_type)

      create_bulk_push_event = changes.size > Gitlab::CurrentSettings.push_event_activities_limit
      merge_request_branches = merge_request_branches_for(ref_type, changes)

      changes.each do |change|
        options = {
          change: change,
          push_options: params[:push_options],
          merge_request_branches: merge_request_branches,
          create_pipelines: under_process_limit?(change),
          execute_project_hooks: execute_project_hooks,
          create_push_event: !create_bulk_push_event
        }

        options[:process_commit_worker_pool] = process_commit_worker_pool if ref_type == :branch

        push_service_class.new(
          project,
          current_user,
          **options
        ).execute
      end

      create_bulk_push_event(ref_type, action, changes) if create_bulk_push_event
    end

    def under_process_limit?(change)
      change[:index] < process_limit || Feature.enabled?(:git_push_create_all_pipelines, project)
    end

    def process_limit
      PIPELINE_PROCESS_LIMIT
    end

    def warn_if_over_process_limit(changes)
      return unless process_limit > 0
      return if changes.length <= process_limit

      # We don't know for sure whether the project has CI enabled or CI rules
      # that might excluded pipelines from being created.
      omitted_refs = possible_omitted_pipeline_refs(changes)

      return unless omitted_refs.present?

      # This notification only lets the admin know that we might have skipped some refs.
      Gitlab::AppJsonLogger.info(
        message: "Some pipelines may not have been created because ref count exceeded limit",
        ref_limit: process_limit,
        total_ref_count: changes.length,
        possible_omitted_refs: omitted_refs,
        possible_omitted_ref_count: omitted_refs.length,
        **Gitlab::ApplicationContext.current
      )
    end

    def possible_omitted_pipeline_refs(changes)
      # Pipelines can only be created on pushed for branch creation or updates
      omitted_changes = changes.select do |change|
        change[:index] >= process_limit &&
          change_action(change) != :removed
      end

      # rubocop:disable CodeReuse/ActiveRecord -- not an ActiveRecord model
      # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- not an ActiveRecord model
      omitted_changes.pluck(:ref).sort
      # rubocop:enable CodeReuse/ActiveRecord
      # rubocop:enable Database/AvoidUsingPluckWithoutLimit
    end

    def create_bulk_push_event(ref_type, action, changes)
      EventCreateService.new.bulk_push(
        project,
        current_user,
        Gitlab::DataBuilder::Push.build_bulk(action: action, ref_type: ref_type, changes: changes)
      )
    end

    def push_service_class_for(ref_type)
      return Git::TagPushService if ref_type == :tag

      Git::BranchPushService
    end

    def merge_request_branches_for(ref_type, changes)
      return [] if ref_type == :tag

      MergeRequests::PushedBranchesService.new(project: project, current_user: current_user, params: { changes: changes }).execute
    end

    def perform_housekeeping
      housekeeping = ::Repositories::HousekeepingService.new(project)
      housekeeping.increment!
      housekeeping.execute if housekeeping.needed?
    rescue ::Repositories::HousekeepingService::LeaseTaken
    end

    def process_commit_worker_pool
      @process_commit_worker_pool ||= Gitlab::Git::ProcessCommitWorkerPool.new
    end
  end
end

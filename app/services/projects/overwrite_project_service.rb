# frozen_string_literal: true

module Projects
  class OverwriteProjectService < BaseService
    def execute(source_project)
      return unless source_project && source_project.namespace == @project.namespace

      start_time = ::Gitlab::Metrics::System.monotonic_time

      Project.transaction do
        move_before_destroy_relationships(source_project)
        # Reset is required in order to get the proper
        # uncached fork network method calls value.
        destroy_old_project(source_project.reset)
        rename_project(source_project.name, source_project.path)

        @project
      end
    # Projects::DestroyService can raise Exceptions, but we don't want
    # to pass that kind of exception to the caller. Instead, we change it
    # for a StandardError exception
    rescue Exception => e # rubocop:disable Lint/RescueException
      attempt_restore_repositories(source_project)

      if e.instance_of?(Exception)
        raise StandardError, e.message
      else
        raise
      end

    ensure
      track_service(start_time, source_project, e)
    end

    private

    def track_service(start_time, source_project, exception)
      return if ::Feature.disabled?(:project_overwrite_service_tracking, source_project, default_enabled: :yaml)

      duration = ::Gitlab::Metrics::System.monotonic_time - start_time

      Gitlab::AppJsonLogger.info(class: self.class.name,
                                 namespace_id: source_project.namespace.id,
                                 project_id: source_project.id,
                                 duration_s: duration.to_f,
                                 error: exception.class.name)
    end

    def move_before_destroy_relationships(source_project)
      options = { remove_remaining_elements: false }

      ::Projects::MoveUsersStarProjectsService.new(@project, @current_user).execute(source_project, **options)
      ::Projects::MoveAccessService.new(@project, @current_user).execute(source_project, **options)
      ::Projects::MoveDeployKeysProjectsService.new(@project, @current_user).execute(source_project, **options)
      ::Projects::MoveNotificationSettingsService.new(@project, @current_user).execute(source_project, **options)
      ::Projects::MoveForksService.new(@project, @current_user).execute(source_project, **options)
      ::Projects::MoveLfsObjectsProjectsService.new(@project, @current_user).execute(source_project, **options)
      add_source_project_to_fork_network(source_project)
    end

    def destroy_old_project(source_project)
      # Delete previous project (synchronously) and unlink relations
      ::Projects::DestroyService.new(source_project, @current_user).execute
    end

    def rename_project(name, path)
      # Update de project's name and path to the original name/path
      ::Projects::UpdateService.new(@project,
                                    @current_user,
                                    { name: name, path: path })
                               .execute
    end

    def attempt_restore_repositories(project)
      ::Projects::DestroyRollbackService.new(project, @current_user).execute
    end

    def add_source_project_to_fork_network(source_project)
      return unless @project.fork_network

      # Because they have moved all references in the fork network from the source_project
      # we won't be able to query the database (only through its cached data),
      # for its former relationships. That's why we're adding it to the network
      # as a fork of the target project
      ForkNetworkMember.create!(fork_network: @project.fork_network,
                                project: source_project,
                                forked_from_project: @project)
    end
  end
end

# frozen_string_literal: true

module Projects
  class OverwriteProjectService < BaseService
    def execute(source_project)
      return unless source_project && source_project.namespace_id == @project.namespace_id

      start_time = ::Gitlab::Metrics::System.monotonic_time
      original_source_name = source_project.name
      original_source_path = source_project.path
      tmp_source_name, tmp_source_path = tmp_source_project_name(source_project)

      move_relationships_between(source_project, @project)

      source_project_rename = rename_project(source_project, tmp_source_name, tmp_source_path)

      if source_project_rename[:status] == :error
        raise 'Source project rename failed during project overwrite'
      end

      new_project_rename = rename_project(@project, original_source_name, original_source_path)

      if new_project_rename[:status] == :error
        rename_project(source_project, original_source_name, original_source_path)

        raise 'New project rename failed during project overwrite'
      end

      schedule_source_project_deletion(source_project)

      @project
    rescue StandardError => e
      move_relationships_between(@project, source_project)
      remove_source_project_from_fork_network(source_project)

      raise e
    ensure
      track_service(start_time, source_project, e)
    end

    private

    def track_service(start_time, source_project, exception)
      duration = ::Gitlab::Metrics::System.monotonic_time - start_time

      Gitlab::AppJsonLogger.info(
        class: self.class.name,
        namespace_id: source_project.namespace_id,
        project_id: source_project.id,
        duration_s: duration.to_f,
        error: exception.class.name
      )
    end

    def move_relationships_between(source_project, target_project)
      options = { remove_remaining_elements: false }

      Project.transaction do
        ::Projects::MoveUsersStarProjectsService.new(target_project, @current_user).execute(source_project, **options)
        ::Projects::MoveAccessService.new(target_project, @current_user).execute(source_project, **options)
        ::Projects::MoveDeployKeysProjectsService.new(target_project, @current_user).execute(source_project, **options)
        ::Projects::MoveNotificationSettingsService.new(target_project, @current_user).execute(source_project, **options)
        ::Projects::MoveForksService.new(target_project, @current_user).execute(source_project, **options)
        ::Projects::MoveLfsObjectsProjectsService.new(target_project, @current_user).execute(source_project, **options)

        add_source_project_to_fork_network(source_project)
      end
    end

    def schedule_source_project_deletion(source_project)
      ::Projects::DestroyService.new(source_project, @current_user).async_execute
    end

    def rename_project(target_project, name, path)
      ::Projects::UpdateService.new(target_project, @current_user, { name: name, path: path }).execute
    end

    def add_source_project_to_fork_network(source_project)
      return if source_project == @project
      return unless fork_network

      # Because they have moved all references in the fork network from the source_project
      # we won't be able to query the database (only through its cached data),
      # for its former relationships. That's why we're adding it to the network
      # as a fork of the target project
      ForkNetworkMember.create!(
        fork_network: fork_network,
        project: source_project,
        forked_from_project: @project
      )
    end

    def remove_source_project_from_fork_network(source_project)
      return unless fork_network

      fork_member = ForkNetworkMember.find_by( # rubocop: disable CodeReuse/ActiveRecord
        fork_network: fork_network,
        project: source_project,
        forked_from_project: @project)

      fork_member&.destroy
    end

    def tmp_source_project_name(source_project)
      random_string = SecureRandom.hex
      tmp_name = "#{source_project.name}-old-#{random_string}"
      tmp_path = "#{source_project.path}-old-#{random_string}"

      [tmp_name, tmp_path]
    end

    def fork_network
      @project.fork_network_member&.fork_network
    end
  end
end

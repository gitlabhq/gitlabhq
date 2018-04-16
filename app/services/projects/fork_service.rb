module Projects
  class ForkService < BaseService
    def execute(fork_to_project = nil)
      if fork_to_project
        link_existing_project(fork_to_project)
      else
        fork_new_project
      end
    end

    private

    def link_existing_project(fork_to_project)
      return if fork_to_project.forked?

      link_fork_network(fork_to_project)

      fork_to_project
    end

    def fork_new_project
      new_params = {
        forked_from_project_id: @project.id,
        visibility_level:       allowed_visibility_level,
        description:            @project.description,
        name:                   @project.name,
        path:                   @project.path,
        shared_runners_enabled: @project.shared_runners_enabled,
        namespace_id:           target_namespace.id
      }

      if @project.avatar.present? && @project.avatar.image?
        new_params[:avatar] = @project.avatar
      end

      new_project = CreateService.new(current_user, new_params).execute
      return new_project unless new_project.persisted?

      builds_access_level = @project.project_feature.builds_access_level
      new_project.project_feature.update_attributes(builds_access_level: builds_access_level)

      link_fork_network(new_project)

      new_project
    end

    def fork_network
      if @project.fork_network
        @project.fork_network
      elsif forked_from_project = @project.forked_from_project
        # TODO: remove this case when all background migrations have completed
        # this only happens when a project had a `forked_project_link` that was
        # not migrated to the `fork_network` relation
        forked_from_project.fork_network || forked_from_project.create_root_of_fork_network
      else
        @project.create_root_of_fork_network
      end
    end

    def link_fork_network(fork_to_project)
      fork_network.fork_network_members.create(project: fork_to_project,
                                               forked_from_project: @project)

      # TODO: remove this when ForkedProjectLink model is removed
      unless fork_to_project.forked_project_link
        fork_to_project.create_forked_project_link(forked_to_project: fork_to_project,
                                                   forked_from_project: @project)
      end

      # Needed to force Rails to reload the has_one fork_network association
      fork_to_project.reload
      refresh_forks_count
    end

    def refresh_forks_count
      Projects::ForksCountService.new(@project).refresh_cache
    end

    def target_namespace
      @target_namespace ||= @params[:namespace] || current_user.namespace
    end

    def allowed_visibility_level
      target_level = [@project.visibility_level, target_namespace.visibility_level].min

      Gitlab::VisibilityLevel.closest_allowed_level(target_level)
    end
  end
end

# frozen_string_literal: true

module Projects
  class ForkService < BaseService
    def execute(fork_to_project = nil)
      forked_project =
        if fork_to_project
          link_existing_project(fork_to_project)
        else
          fork_new_project
        end

      refresh_forks_count if forked_project&.saved?

      forked_project
    end

    private

    def allowed_fork?
      current_user.can?(:fork_project, @project)
    end

    def link_existing_project(fork_to_project)
      return if fork_to_project.forked?

      build_fork_network_member(fork_to_project)

      if link_fork_network(fork_to_project)
        # A forked project stores its LFS objects in the `forked_from_project`.
        # So the LFS objects become inaccessible, and therefore delete them from
        # the database so they'll get cleaned up.
        #
        # TODO: refactor this to get the correct lfs objects when implementing
        #       https://gitlab.com/gitlab-org/gitlab-foss/issues/39769
        fork_to_project.lfs_objects_projects.delete_all

        fork_to_project
      end
    end

    def fork_new_project
      new_params = {
        visibility_level:          allowed_visibility_level,
        description:               @project.description,
        name:                      target_name,
        path:                      target_path,
        shared_runners_enabled:    @project.shared_runners_enabled,
        namespace_id:              target_namespace.id,
        fork_network:              fork_network,
        ci_config_path:            @project.ci_config_path,
        # We need to set ci_default_git_depth to 0 for the forked project when
        # @project.ci_default_git_depth is nil in order to keep the same behaviour
        # and not get ProjectCiCdSetting::DEFAULT_GIT_DEPTH set on create
        ci_cd_settings_attributes: { default_git_depth: @project.ci_default_git_depth || 0 },
        # We need to assign the fork network membership after the project has
        # been instantiated to avoid ActiveRecord trying to create it when
        # initializing the project, as that would cause a foreign key constraint
        # exception.
        relations_block:           -> (project) { build_fork_network_member(project) },
        skip_disk_validation:      skip_disk_validation
      }

      if @project.avatar.present? && @project.avatar.image?
        new_params[:avatar] = @project.avatar
      end

      new_params.merge!(@project.object_pool_params)

      new_project = CreateService.new(current_user, new_params).execute
      return new_project unless new_project.persisted?

      # Set the forked_from_project relation after saving to avoid having to
      # reload the project to reset the association information and cause an
      # extra query.
      new_project.forked_from_project = @project

      builds_access_level = @project.project_feature.builds_access_level
      new_project.project_feature.update(builds_access_level: builds_access_level)

      new_project
    end

    def fork_network
      @fork_network ||= @project.fork_network || @project.build_root_of_fork_network
    end

    def build_fork_network_member(fork_to_project)
      if allowed_fork?
        fork_to_project.build_fork_network_member(forked_from_project: @project,
                                                  fork_network: fork_network)
      else
        fork_to_project.errors.add(:forked_from_project_id, 'is forbidden')
      end
    end

    def link_fork_network(fork_to_project)
      return if fork_to_project.errors.any?

      fork_to_project.fork_network_member.save
    end

    def refresh_forks_count
      Projects::ForksCountService.new(@project).refresh_cache
    end

    def target_path
      @target_path ||= @params[:path] || @project.path
    end

    def target_name
      @target_name ||= @params[:name] || @project.name
    end

    def target_namespace
      @target_namespace ||= @params[:namespace] || current_user.namespace
    end

    def skip_disk_validation
      @skip_disk_validation ||= @params[:skip_disk_validation] || false
    end

    def allowed_visibility_level
      target_level = [@project.visibility_level, target_namespace.visibility_level].min

      Gitlab::VisibilityLevel.closest_allowed_level(target_level)
    end
  end
end

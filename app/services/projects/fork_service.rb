# frozen_string_literal: true

module Projects
  class ForkService < BaseService
    def execute(fork_to_project = nil)
      forked_project = fork_to_project ? link_existing_project(fork_to_project) : fork_new_project

      refresh_forks_count if forked_project&.saved?

      forked_project
    end

    def valid_fork_targets(options = {})
      @valid_fork_targets ||= ForkTargetsFinder.new(@project, current_user).execute(options)
    end

    def valid_fork_target?(namespace = target_namespace)
      return true if current_user.admin?

      valid_fork_targets.include?(namespace)
    end

    private

    def link_existing_project(fork_to_project)
      return if fork_to_project.forked?

      build_fork_network_member(fork_to_project)

      fork_to_project if link_fork_network(fork_to_project)
    end

    def fork_new_project
      new_project = CreateService.new(current_user, new_fork_params).execute
      return new_project unless new_project.persisted?

      new_project.project_feature.update!(
        @project.project_feature.slice(ProjectFeature::FEATURES.map { |f| "#{f}_access_level" })
      )

      new_project
    end

    def new_fork_params
      new_params = {
        forked_from_project:       @project,
        visibility_level:          target_visibility_level,
        description:               target_description,
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

      new_params
    end

    def allowed_fork?
      current_user.can?(:fork_project, @project)
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

    def target_description
      @target_description ||= @params[:description] || @project.description
    end

    def target_namespace
      @target_namespace ||= @params[:namespace] || current_user.namespace
    end

    def skip_disk_validation
      @skip_disk_validation ||= @params[:skip_disk_validation] || false
    end

    def target_visibility_level
      target_level = [@project.visibility_level, target_namespace.visibility_level].min
      target_level = [target_level, Gitlab::VisibilityLevel.level_value(params[:visibility])].min if params.key?(:visibility)

      Gitlab::VisibilityLevel.closest_allowed_level(target_level)
    end
  end
end

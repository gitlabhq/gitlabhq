# frozen_string_literal: true

module Environments
  class StopService < BaseService
    attr_reader :ref

    def execute(environment)
      unless can?(current_user, :stop_environment, environment)
        return ServiceResponse.error(
          message: 'Unauthorized to stop the environment',
          payload: { environment: environment }
        )
      end

      unsafe_execute!(environment)
    end

    ##
    # Stops the environment without checking user permissions. This
    # should only be used if initiated by a system action and a user
    # cannot be specified.
    def unsafe_execute!(environment)
      if params[:force]
        actions = []

        environment.stop_complete!
      else
        actions = environment.stop_with_actions!
      end

      unless environment.saved_change_to_attribute?(:state)
        return ServiceResponse.error(
          message: 'Attempted to stop the environment but failed to change the status',
          payload: { environment: environment }
        )
      end

      ServiceResponse.success(payload: { environment: environment, actions: actions })
    end

    def execute_for_branch(branch_name)
      @ref = branch_name

      return unless @ref.present?

      environments.each { |environment| execute(environment) }
    end

    def execute_for_merge_request_pipeline(merge_request)
      return unless merge_request.diff_head_pipeline&.merge_request?

      created_environments = merge_request.created_environments

      if created_environments.any?
        # This log message can be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/372965
        Gitlab::AppJsonLogger.info(message: 'Running new dynamic environment stop logic', project_id: project.id)
        created_environments.each { |env| execute(env) }
      else
        environments_in_head_pipeline = merge_request.environments_in_head_pipeline(deployment_status: :success)
        environments_in_head_pipeline.each { |env| execute(env) }

        if environments_in_head_pipeline.any?
          # If we don't see a message often, we'd be able to remove this path. (or likely in GitLab 16.0)
          # See https://gitlab.com/gitlab-org/gitlab/-/issues/372965
          Gitlab::AppJsonLogger.info(message: 'Running legacy dynamic environment stop logic', project_id: project.id)
        end
      end
    end

    private

    def environments
      @environments ||= Environments::EnvironmentsByDeploymentsFinder
        .new(project, current_user, ref: @ref, recently_updated: true)
        .execute
    end
  end
end

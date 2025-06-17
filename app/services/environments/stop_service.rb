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

      if environment.stopped? || environment.stopping?
        delete_managed_resources(environment)

        ServiceResponse.success(payload: { environment: environment, actions: actions })
      else
        ServiceResponse.error(
          message: 'Attempted to stop the environment but failed to change the status',
          payload: { environment: environment }
        )
      end
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
        created_environments.each do |env|
          # This log message can be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/372965
          Gitlab::AppJsonLogger.info(
            message: 'Running new dynamic environment stop logic',
            project_id: project.id,
            environment_id: env.id,
            merge_request_id: merge_request.id,
            pipeline_id: merge_request.diff_head_pipeline.id
          )

          execute(env)
        end
      else
        environments_in_head_pipeline = merge_request.environments_in_head_pipeline(deployment_status: :success)

        environments_in_head_pipeline.each do |env|
          # This log message can be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/372965
          Gitlab::AppJsonLogger.info(
            message: 'Running legacy dynamic environment stop logic',
            project_id: project.id,
            environment_id: env.id,
            merge_request_id: merge_request.id,
            pipeline_id: merge_request.diff_head_pipeline.id
          )

          execute(env)
        end
      end
    end

    private

    def environments
      @environments ||= Environments::EnvironmentsByDeploymentsFinder
        .new(project, current_user, ref: @ref, recently_updated: true)
        .execute
    end

    def delete_managed_resources(environment)
      Environments::DeleteManagedResourcesService.new(environment, current_user:).execute
    end
  end
end

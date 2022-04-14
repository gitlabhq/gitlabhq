# frozen_string_literal: true

module Environments
  class StopService < BaseService
    attr_reader :ref

    def execute(environment)
      return unless can?(current_user, :stop_environment, environment)

      environment.stop_with_actions!(current_user)
    end

    def execute_for_branch(branch_name)
      @ref = branch_name

      return unless @ref.present?

      environments.each { |environment| execute(environment) }
    end

    def execute_for_merge_request(merge_request)
      merge_request.environments_in_head_pipeline(deployment_status: :success).each do |environment|
        execute(environment)
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

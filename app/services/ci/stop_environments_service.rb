# frozen_string_literal: true

module Ci
  class StopEnvironmentsService < BaseService
    attr_reader :ref

    def execute(branch_name)
      @ref = branch_name

      return unless @ref.present?

      environments.each { |environment| stop(environment) }
    end

    def execute_for_merge_request(merge_request)
      merge_request.environments.each { |environment| stop(environment) }
    end

    private

    def environments
      @environments ||= EnvironmentsFinder
        .new(project, current_user, ref: @ref, recently_updated: true)
        .execute
    end

    def stop(environment)
      return unless environment.stop_action_available?
      return unless can?(current_user, :stop_environment, environment)

      environment.stop_with_action!(current_user)
    end
  end
end

# frozen_string_literal: true

module Environments
  class StopService < BaseService
    attr_reader :ref

    def execute(environment)
      return unless can?(current_user, :stop_environment, environment)

      environment.stop_with_action!(current_user)
    end

    def execute_for_branch(branch_name)
      @ref = branch_name

      return unless @ref.present?

      environments.each { |environment| execute(environment) }
    end

    def execute_for_merge_request(merge_request)
      merge_request.environments.each { |environment| execute(environment) }
    end

    ##
    # This method is for stopping multiple environments in a batch style.
    # The maximum acceptable count of environments is roughly 5000. Please
    # apply acceptable `LIMIT` clause to the `environments` relation.
    def self.execute_in_batch(environments)
      stop_actions = environments.stop_actions.load

      environments.update_all(auto_stop_at: nil, state: 'stopped')

      stop_actions.each do |stop_action|
        stop_action.play(stop_action.user)
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, deployable_id: stop_action.id)
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

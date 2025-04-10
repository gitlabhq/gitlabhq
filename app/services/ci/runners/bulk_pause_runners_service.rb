# frozen_string_literal: true

module Ci
  module Runners
    class BulkPauseRunnersService
      attr_reader :current_user, :runners

      RUNNER_LIMIT = 50

      # @param runners [Array<Ci::Runner>] the runners to pause or unpause
      # @param current_user [User] the user performing the operation
      # @param paused [Boolean] action of pausing or unpausing
      def initialize(runners:, current_user:, paused:)
        @runners = runners
        @current_user = current_user
        @paused = paused
      end

      def execute
        if runners.present?
          # pause the runners
          return pause_runners(@paused)
        end

        ServiceResponse.success(payload: { updated_count: 0, updated_runners: [], errors: [] })
      end

      private

      def pause_runners(paused)
        active = !paused
        runner_count = runners.limit(RUNNER_LIMIT + 1).count
        authorized_runners_ids, unauthorized_runners_ids = compute_authorized_runners
        runners_to_be_updated = Ci::Runner.id_in(authorized_runners_ids)
        runners_to_be_updated.update(active: active)
        ServiceResponse.success(
          payload: {
            updated_count: runners_to_be_updated.count,
            updated_runners: runners_to_be_updated,
            errors: error_messages(runner_count, authorized_runners_ids, unauthorized_runners_ids)
          })
      end

      def compute_authorized_runners
        current_user.ci_owned_runners.load # preload the owned runners to avoid an N+1

        authorized_runners, unauthorized_runners =
          runners.limit(RUNNER_LIMIT)
            .partition { |runner| Ability.allowed?(current_user, :update_runner, runner) }
        [authorized_runners.map(&:id), unauthorized_runners.map(&:id)]
      end

      def error_messages(runner_count, authorized_runners_ids, unauthorized_runners_ids)
        errors = []

        if runner_count > RUNNER_LIMIT
          errors << "Can only pause up to #{RUNNER_LIMIT} runners per call. Ignored the remaining runner(s)."
        end

        if authorized_runners_ids.empty?
          errors << "User does not have permission to update / pause any of the runners"
        elsif unauthorized_runners_ids.any?
          failed_ids = unauthorized_runners_ids.map { |runner_id| "##{runner_id}" }.join(', ')
          errors << "User does not have permission to update / pause runner(s) #{failed_ids}"
        end

        errors
      end
    end
  end
end

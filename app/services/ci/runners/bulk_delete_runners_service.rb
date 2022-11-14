# frozen_string_literal: true

module Ci
  module Runners
    class BulkDeleteRunnersService
      attr_reader :runners

      RUNNER_LIMIT = 50

      # @param runners [Array<Ci::Runner>] the runners to unregister/destroy
      # @param current_user [User] the user performing the operation
      def initialize(runners:, current_user:)
        @runners = runners
        @current_user = current_user
      end

      def execute
        if @runners
          # Delete a few runners immediately
          return delete_runners
        end

        ServiceResponse.success(payload: { deleted_count: 0, deleted_ids: [], errors: [] })
      end

      private

      def delete_runners
        runner_count = @runners.limit(RUNNER_LIMIT + 1).count
        authorized_runners_ids, unauthorized_runners_ids = compute_authorized_runners
        # rubocop:disable CodeReuse/ActiveRecord
        runners_to_be_deleted =
          Ci::Runner
            .where(id: authorized_runners_ids)
            .preload([:taggings, :runner_namespaces, :runner_projects])
        # rubocop:enable CodeReuse/ActiveRecord
        deleted_ids = runners_to_be_deleted.destroy_all.map(&:id) # rubocop:disable Cop/DestroyAll

        ServiceResponse.success(
          payload: {
            deleted_count: deleted_ids.count,
            deleted_ids: deleted_ids,
            errors: error_messages(runner_count, authorized_runners_ids, unauthorized_runners_ids)
          })
      end

      def compute_authorized_runners
        # rubocop:disable CodeReuse/ActiveRecord
        @current_user.ci_owned_runners.load # preload the owned runners to avoid an N+1
        authorized_runners, unauthorized_runners =
          @runners.limit(RUNNER_LIMIT)
                  .partition { |runner| Ability.allowed?(@current_user, :delete_runner, runner) }
        # rubocop:enable CodeReuse/ActiveRecord

        [authorized_runners.map(&:id), unauthorized_runners.map(&:id)]
      end

      def error_messages(runner_count, authorized_runners_ids, unauthorized_runners_ids)
        errors = []

        if runner_count > RUNNER_LIMIT
          errors << "Can only delete up to #{RUNNER_LIMIT} runners per call. Ignored the remaining runner(s)."
        end

        if authorized_runners_ids.empty?
          errors << "User does not have permission to delete any of the runners"
        elsif unauthorized_runners_ids.any?
          failed_ids = unauthorized_runners_ids.map { |runner_id| "##{runner_id}" }.join(', ')
          errors << "User does not have permission to delete runner(s) #{failed_ids}"
        end

        errors
      end
    end
  end
end

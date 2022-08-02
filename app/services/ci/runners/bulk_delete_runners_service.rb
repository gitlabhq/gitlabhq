# frozen_string_literal: true

module Ci
  module Runners
    class BulkDeleteRunnersService
      attr_reader :runners

      RUNNER_LIMIT = 50

      # @param runners [Array<Ci::Runner, Integer>] the runners to unregister/destroy
      def initialize(runners:)
        @runners = runners
      end

      def execute
        if @runners
          # Delete a few runners immediately
          return delete_runners
        end

        { deleted_count: 0, deleted_ids: [] }
      end

      private

      def delete_runners
        # rubocop:disable CodeReuse/ActiveRecord
        runners_to_be_deleted = Ci::Runner.where(id: @runners).limit(RUNNER_LIMIT)
        # rubocop:enable CodeReuse/ActiveRecord
        deleted_ids = runners_to_be_deleted.destroy_all.map(&:id) # rubocop: disable Cop/DestroyAll

        { deleted_count: deleted_ids.count, deleted_ids: deleted_ids }
      end
    end
  end
end

# frozen_string_literal: true

module Todos
  module Destroy
    class DestroyedIssuableService
      BATCH_SIZE = 100

      # Since we are moving towards work items, in some instances we create todos with
      # `target_type: WorkItem` in other instances we still create todos with `target_type: Issue`
      # So when an issue/work item is deleted, we just make sure to delete todos for both target types
      BOUND_TARGET_TYPES = %w[Issue WorkItem].freeze

      def initialize(target_id, target_type)
        @target_id = target_id
        @target_type = BOUND_TARGET_TYPES.include?(target_type) ? BOUND_TARGET_TYPES : target_type
      end

      def execute
        relation = Todo.for_target(target_id).for_type(target_type).limit(BATCH_SIZE)

        loop do
          result = relation.delete_all_returning(:user_id)

          break if result.empty?

          user_ids = result.map { |row| row['user_id'] }.uniq

          invalidate_todos_cache_counts(user_ids)
        end
      end

      private

      attr_reader :target_id, :target_type

      def invalidate_todos_cache_counts(user_ids)
        user_ids.each do |id|
          # Only build a user instance since we only need its ID for
          # `User#invalidate_todos_cache_counts` to work.
          User.new(id: id).invalidate_todos_cache_counts
        end
      end
    end
  end
end

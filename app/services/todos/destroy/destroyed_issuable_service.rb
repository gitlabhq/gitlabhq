# frozen_string_literal: true

module Todos
  module Destroy
    class DestroyedIssuableService
      BATCH_SIZE = 100

      def initialize(target_id, target_type)
        @target_id = target_id
        @target_type = target_type
      end

      def execute
        inner_query = Todo.select(:id).for_target(target_id).for_type(target_type).limit(BATCH_SIZE)

        delete_query = <<~SQL
        DELETE FROM "#{Todo.table_name}"
        WHERE id IN (#{inner_query.to_sql})
        RETURNING user_id
        SQL

        loop do
          result = ActiveRecord::Base.connection.execute(delete_query)

          break if result.cmd_tuples == 0

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

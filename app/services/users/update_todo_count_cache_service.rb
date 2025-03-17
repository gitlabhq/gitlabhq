# frozen_string_literal: true

module Users
  class UpdateTodoCountCacheService < BaseService
    QUERY_BATCH_SIZE = 10

    attr_reader :user_ids

    # user_ids - An array of User IDs
    def initialize(user_ids)
      @user_ids = user_ids
    end

    def execute
      user_ids.each_slice(QUERY_BATCH_SIZE) do |user_ids_batch|
        todo_counts = Todo.for_user(user_ids_batch).pending_count_by_user_id

        user_ids_batch.each do |user_id|
          count = todo_counts.fetch(user_id, 0)

          Rails.cache.write(
            ['users', user_id, "todos_pending_count"],
            count,
            expires_in: User::COUNT_CACHE_VALIDITY_PERIOD
          )
        end
      end
    end
  end
end

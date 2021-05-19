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
        todo_counts = Todo.for_user(user_ids_batch).count_grouped_by_user_id_and_state

        user_ids_batch.each do |user_id|
          update_count_cache(user_id, todo_counts, :done)
          update_count_cache(user_id, todo_counts, :pending)
        end
      end
    end

    private

    def update_count_cache(user_id, todo_counts, state)
      count = todo_counts.fetch([user_id, state.to_s], 0)

      Rails.cache.write(
        ['users', user_id, "todos_#{state}_count"],
        count,
        expires_in: User::COUNT_CACHE_VALIDITY_PERIOD
      )
    end
  end
end

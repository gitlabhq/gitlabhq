# frozen_string_literal: true

module Users
  class UpdateTodoCountCacheService < BaseService
    QUERY_BATCH_SIZE = 10

    attr_reader :users

    # users - An array of User objects
    def initialize(users)
      @users = users
    end

    def execute
      users.each_slice(QUERY_BATCH_SIZE) do |users_batch|
        todo_counts = Todo.for_user(users_batch).count_grouped_by_user_id_and_state

        users_batch.each do |user|
          update_count_cache(user, todo_counts, :done)
          update_count_cache(user, todo_counts, :pending)
        end
      end
    end

    private

    def update_count_cache(user, todo_counts, state)
      count = todo_counts.fetch([user.id, state.to_s], 0)
      expiration_time = user.count_cache_validity_period

      Rails.cache.write(['users', user.id, "todos_#{state}_count"], count, expires_in: expiration_time)
    end
  end
end

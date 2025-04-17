# frozen_string_literal: true

module Todos
  class DeleteAllDoneWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers
    include EachBatch

    data_consistency :sticky
    idempotent!

    sidekiq_options retry: true
    include TodosDestroyerQueue

    LOCK_TIMEOUT = 1.hour
    BATCH_DELETE_SIZE = 10_000
    SUB_BATCH_DELETE_SIZE = 100
    SLEEP_INTERVAL = 100
    MAX_RUNTIME = 2.minutes

    def perform(user_id, time)
      runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)
      delete_until = time.to_datetime
      pause_ms = SLEEP_INTERVAL
      # rubocop: disable CodeReuse/ActiveRecord -- we need to keep the logic in the worker
      in_lock("#{self.class.name.underscore}_#{user_id}", ttl: LOCK_TIMEOUT, retries: 0) do
        Todo.where(user_id: user_id)
            .with_state(:done)
            .each_batch(of: BATCH_DELETE_SIZE) do |batch|
          batch.each_batch(of: SUB_BATCH_DELETE_SIZE) do |sub_batch|
            sql = <<~SQL
              WITH sub_batch AS MATERIALIZED (
                #{sub_batch.select(:id, :updated_at).limit(SUB_BATCH_DELETE_SIZE).to_sql}
              ), filtered_relation AS MATERIALIZED (
                SELECT id FROM sub_batch WHERE updated_at < '#{delete_until.to_fs(:db)}' LIMIT #{SUB_BATCH_DELETE_SIZE}
              )
              DELETE FROM todos WHERE id IN (SELECT id FROM filtered_relation)
            SQL

            Todo.connection.exec_query(sql)

            sleep(pause_ms * 0.001) # Avoid hitting the database too hard
          end

          next unless runtime_limiter.over_time?

          self.class.perform_in(MAX_RUNTIME, user_id, time)

          break
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end

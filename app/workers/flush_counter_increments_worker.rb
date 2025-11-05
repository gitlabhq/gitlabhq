# frozen_string_literal: true

# Invoked by CounterAttribute concern when incrementing counter
# attributes. The method `flush_increments_to_database!` that
# this worker uses is itself idempotent as it runs with exclusive
# lease to ensure that only one instance at the time can flush
# increments from Redis to the database.
class FlushCounterIncrementsWorker
  include ApplicationWorker

  data_consistency :delayed

  sidekiq_options retry: 3
  loggable_arguments 0, 2
  defer_on_database_health_signal :gitlab_main, [:project_daily_statistics], 1.minute
  # The increments in `ProjectStatistics` are owned by several teams depending
  # on the counter, but rubocop will not allow shared for workers
  # Passed model_names updated primarily belong to source_code_management
  # See: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/211119
  feature_category :source_code_management

  urgency :low
  deduplicate :until_executed, including_scheduled: true, if_deduplicated: :reschedule_once

  idempotent!

  max_concurrency_limit_percentage 0.5

  def perform(model_name, model_id, attribute)
    return unless self.class.const_defined?(model_name)

    model_class = model_name.constantize
    model = model_class.primary_key_in([model_id]).take # rubocop: disable CodeReuse/ActiveRecord -- we work on a dynamic model name
    return unless model

    Gitlab::Counters::BufferedCounter.new(model, attribute).commit_increment!
  end
end

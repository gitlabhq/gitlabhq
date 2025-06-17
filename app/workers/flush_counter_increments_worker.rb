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
  # on the counter
  feature_category :continuous_integration

  urgency :low
  deduplicate :until_executed, including_scheduled: true, if_deduplicated: :reschedule_once

  idempotent!

  def perform(model_name, model_id, attribute)
    return unless self.class.const_defined?(model_name)

    model_class = model_name.constantize
    model = model_class.find_by_id(model_id)
    return unless model

    Gitlab::Counters::BufferedCounter.new(model, attribute).commit_increment!
  end
end

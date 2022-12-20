# frozen_string_literal: true

# Add capabilities to increment a numeric model attribute efficiently by
# using Redis and flushing the increments asynchronously to the database
# after a period of time (10 minutes).
# When an attribute is incremented by a value, the increment is added
# to a Redis key. Then, FlushCounterIncrementsWorker will execute
# `flush_increments_to_database!` which removes increments from Redis for a
# given model attribute and updates the values in the database.
#
# @example:
#
#   class ProjectStatistics
#     include CounterAttribute
#
#     counter_attribute :commit_count
#     counter_attribute :storage_size
#   end
#
# It's possible to define a conditional counter attribute. You need to pass a proc
# that must accept a single argument, the object instance on which this concern is
# included.
#
# @example:
#
#   class ProjectStatistics
#     include CounterAttribute
#
#     counter_attribute :conditional_one, if: -> { |object| object.use_counter_attribute? }
#   end
#
# To increment the counter we can use the method:
#   increment_counter(:commit_count, 3)
#
# This method would determine whether it would increment the counter using Redis,
# or fallback to legacy increment on ActiveRecord counters.
#
# It is possible to register callbacks to be executed after increments have
# been flushed to the database. Callbacks are not executed if there are no increments
# to flush.
#
#  counter_attribute_after_commit do |statistic|
#    Namespaces::ScheduleAggregationWorker.perform_async(statistic.namespace_id)
#  end
#
module CounterAttribute
  extend ActiveSupport::Concern
  extend AfterCommitQueue
  include Gitlab::ExclusiveLeaseHelpers
  include Gitlab::Utils::StrongMemoize

  class_methods do
    def counter_attribute(attribute, if: nil)
      counter_attributes << {
        attribute: attribute,
        if_proc: binding.local_variable_get(:if) # can't read `if` directly
      }
    end

    def counter_attributes
      @counter_attributes ||= []
    end

    def after_commit_callbacks
      @after_commit_callbacks ||= []
    end

    # perform registered callbacks after increments have been committed to the database
    def counter_attribute_after_commit(&callback)
      after_commit_callbacks << callback
    end
  end

  def counter_attribute_enabled?(attribute)
    counter_attribute = self.class.counter_attributes.find { |registered| registered[:attribute] == attribute }
    return false unless counter_attribute
    return true unless counter_attribute[:if_proc]

    counter_attribute[:if_proc].call(self)
  end

  def counter(attribute)
    strong_memoize_with(:counter, attribute) do
      # This needs #to_sym because attribute could come from a Sidekiq param,
      # which would be a string.
      build_counter_for(attribute.to_sym)
    end
  end

  def increment_counter(attribute, increment)
    return if increment == 0

    run_after_commit_or_now do
      new_value = counter(attribute).increment(increment)

      log_increment_counter(attribute, increment, new_value)
    end
  end

  def update_counters_with_lease(increments)
    detect_race_on_record(log_fields: { caller: __method__, attributes: increments.keys }) do
      self.class.update_counters(id, increments)
    end
  end

  def reset_counter!(attribute)
    detect_race_on_record(log_fields: { caller: __method__, attributes: attribute }) do
      counter(attribute).reset!
    end

    log_clear_counter(attribute)
  end

  def execute_after_commit_callbacks
    self.class.after_commit_callbacks.each do |callback|
      callback.call(self.reset)
    end
  end

  private

  def build_counter_for(attribute)
    raise ArgumentError, %(attribute "#{attribute}" does not exist) unless has_attribute?(attribute)

    if counter_attribute_enabled?(attribute)
      Gitlab::Counters::BufferedCounter.new(self, attribute)
    else
      Gitlab::Counters::LegacyCounter.new(self, attribute)
    end
  end

  def database_lock_key
    "project:{#{project_id}}:#{self.class}:#{id}"
  end

  # detect_race_on_record uses a lease to monitor access
  # to the project statistics row. This is needed to detect
  # concurrent attempts to increment columns, which could result in a
  # race condition.
  #
  # As the purpose is to detect and warn concurrent attempts,
  # it falls back to direct update on the row if it fails to obtain the lease.
  #
  # It does not guarantee that there will not be any concurrent updates.
  def detect_race_on_record(log_fields: {})
    return yield unless Feature.enabled?(:counter_attribute_db_lease_for_update, project)

    # Ensure attributes is always an array before we log
    log_fields[:attributes] = Array(log_fields[:attributes])

    Gitlab::AppLogger.info(
      message: 'Acquiring lease for project statistics update',
      project_statistics_id: id,
      project_id: project.id,
      **log_fields,
      **Gitlab::ApplicationContext.current
    )

    in_lock(database_lock_key, retries: 0) do
      yield
    end
  rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
    Gitlab::AppLogger.warn(
      message: 'Concurrent project statistics update detected',
      project_statistics_id: id,
      project_id: project.id,
      **log_fields,
      **Gitlab::ApplicationContext.current
    )

    yield
  end

  def log_increment_counter(attribute, increment, new_value)
    payload = Gitlab::ApplicationContext.current.merge(
      message: 'Increment counter attribute',
      attribute: attribute,
      project_id: project_id,
      increment: increment,
      new_counter_value: new_value,
      current_db_value: read_attribute(attribute)
    )

    Gitlab::AppLogger.info(payload)
  end

  def log_clear_counter(attribute)
    payload = Gitlab::ApplicationContext.current.merge(
      message: 'Clear counter attribute',
      attribute: attribute,
      project_id: project_id
    )

    Gitlab::AppLogger.info(payload)
  end
end

# frozen_string_literal: true

require 'sidekiq/api'

Sidekiq::Worker.extend ActiveSupport::Concern

module ApplicationWorker
  extend ActiveSupport::Concern

  include Sidekiq::Worker # rubocop:disable Cop/IncludeSidekiqWorker
  include WorkerAttributes
  include WorkerContext
  include Gitlab::SidekiqVersioning::Worker
  include Gitlab::Loggable

  LOGGING_EXTRA_KEY = 'extra'
  SAFE_PUSH_BULK_LIMIT = 1000

  included do
    prefer_calling_context_feature_category false
    set_queue
    after_set_class_attribute { set_queue }

    def structured_payload(payload = {})
      context = Gitlab::ApplicationContext.current.merge(
        'class' => self.class.name,
        'job_status' => 'running',
        'queue' => self.class.queue,
        'jid' => jid
      )

      build_structured_payload(**payload).merge(context)
    end

    def log_extra_metadata_on_done(key, value)
      @done_log_extra_metadata ||= {}
      @done_log_extra_metadata[key] = value
    end

    def log_hash_metadata_on_done(hash)
      @done_log_extra_metadata ||= {}
      hash.each { |key, value| @done_log_extra_metadata[key] = value }
    end

    def logging_extras
      return {} unless @done_log_extra_metadata

      # Prefix keys with class name to avoid conflicts in Elasticsearch types.
      # Also prefix with "extra." so that we know to log these new fields.
      @done_log_extra_metadata.transform_keys do |k|
        "#{LOGGING_EXTRA_KEY}.#{self.class.name.gsub('::', '_').underscore}.#{k}"
      end
    end
  end

  class_methods do
    extend ::Gitlab::Utils::Override

    def inherited(subclass)
      subclass.set_queue
      subclass.after_set_class_attribute { subclass.set_queue }
    end

    def with_status
      status_from_class = self.sidekiq_options_hash['status_expiration']

      set(status_expiration: status_from_class || Gitlab::SidekiqStatus::DEFAULT_EXPIRATION)
    end

    def deferred(count = 0, by = nil)
      set(deferred: true, deferred_count: count, deferred_by: by)
    end

    def rescheduled_once
      set(rescheduled_once: true)
    end

    def concurrency_limit_resume(buffered_at)
      set(concurrency_limit_resume: true, concurrency_limit_buffered_at: buffered_at)
    end

    def generated_queue_name
      Gitlab::SidekiqConfig::WorkerRouter.queue_name_from_worker_name(self)
    end

    def validate_worker_attributes!
      # Since the delayed data_consistency will use sidekiq built in retry mechanism, it is required that this mechanism
      # is not disabled.
      if retry_disabled? && get_data_consistency_per_database.value?(:delayed)
        raise ArgumentError, "Retry support cannot be disabled if data_consistency is set to :delayed"
      end
    end

    # Checks if sidekiq retry support is disabled
    def retry_disabled?
      get_sidekiq_options['retry'] == 0 || get_sidekiq_options['retry'] == false
    end

    override :sidekiq_options
    def sidekiq_options(opts = {})
      super.tap do
        validate_worker_attributes!
      end
    end

    override :data_consistency
    def data_consistency(default, overrides: nil, feature_flag: nil)
      super

      validate_worker_attributes!
    end

    # Only override perform_at and perform_in since perform_async calls Setter.new(..).perform_async
    # which is handled in the Gitlab::Patch::SidekiqJobSetter.
    %i[perform_at perform_in].each do |name|
      define_method(name) do |*args|
        Gitlab::SidekiqSharding::Router.route(self) do
          super(*args)
        end
      end
    end

    def set_queue
      queue_name = ::Gitlab::SidekiqConfig::WorkerRouter.global.route(self)
      sidekiq_options queue: queue_name # rubocop:disable Cop/SidekiqOptionsQueue

      store_name = ::Gitlab::SidekiqConfig::WorkerRouter.global.store(self)
      sidekiq_options store: store_name
    end

    def queue_namespace(new_namespace = nil)
      if new_namespace
        sidekiq_options queue_namespace: new_namespace

        set_queue
      else
        get_sidekiq_options['queue_namespace']&.to_s
      end
    end

    def queue
      get_sidekiq_options['queue'].to_s
    end

    # Set/get which arguments can be logged and sent to Sentry.
    #
    # Numeric arguments are logged by default, so there is no need to
    # list those.
    #
    # Non-numeric arguments must be listed by position, as Sidekiq
    # cannot see argument names.
    #
    def loggable_arguments(*args)
      if args.any?
        @loggable_arguments = args
      else
        @loggable_arguments || []
      end
    end

    def log_bulk_perform_async?
      @log_bulk_perform_async
    end

    def log_bulk_perform_async!
      @log_bulk_perform_async = true
    end

    def bulk_perform_async(args_list)
      if log_bulk_perform_async?
        Sidekiq.logger.info('class' => self.name, 'args_list' => args_list, 'args_list_count' => args_list.length, 'message' => 'Inserting multiple jobs')
      end

      do_push_bulk(args_list).tap do |job_ids|
        if log_bulk_perform_async?
          Sidekiq.logger.info('class' => self.name, 'jid_list' => job_ids, 'jid_list_count' => job_ids.length, 'message' => 'Completed JID insertion')
        end
      end
    end

    def bulk_perform_in(delay, args_list, batch_size: nil, batch_delay: nil)
      now = Time.now.to_i
      base_schedule_at = now + delay.to_i

      if base_schedule_at <= now
        raise ArgumentError, 'The schedule time must be in the future!'
      end

      schedule_at = base_schedule_at

      if batch_size && batch_delay
        batch_size = batch_size.to_i
        batch_delay = batch_delay.to_i

        raise ArgumentError, 'batch_size should be greater than 0' unless batch_size > 0
        raise ArgumentError, 'batch_delay should be greater than 0' unless batch_delay > 0

        # build an array of schedules corresponding to each item in `args_list`
        bulk_schedule_at = Array.new(args_list.size) do |index|
          batch_number = index / batch_size
          base_schedule_at + (batch_number * batch_delay)
        end

        schedule_at = bulk_schedule_at
      end

      Gitlab::SidekiqSharding::Router.route(self) do
        in_safe_limit_batches(args_list, schedule_at) do |args_batch, schedule_at_for_batch|
          Sidekiq::Client.push_bulk('class' => self, 'args' => args_batch, 'at' => schedule_at_for_batch)
        end
      end
    end

    def with_ip_address_state
      set(ip_address_state: ::Gitlab::IpAddressState.current)
    end

    private

    def do_push_bulk(args_list)
      Gitlab::SidekiqSharding::Router.route(self) do
        in_safe_limit_batches(args_list) do |args_batch, _|
          Sidekiq::Client.push_bulk('class' => self, 'args' => args_batch)
        end
      end
    end

    def in_safe_limit_batches(args_list, schedule_at = nil, safe_limit = SAFE_PUSH_BULK_LIMIT)
      # `schedule_at` could be one of
      # - nil.
      # - a single Numeric that represents time, like `30.minutes.from_now.to_i`.
      # - an array, where each element is a Numeric that reprsents time.
      #    - Each element in this array would correspond to the time at which
      #    - the job in `args_list` at the corresponding index needs to be scheduled.

      # In the case where `schedule_at` is an array of Numeric, it needs to be sliced
      # in the same manner as the `args_list`, with each slice containing `safe_limit`
      # number of elements.
      schedule_at = schedule_at.each_slice(safe_limit).to_a if schedule_at.is_a?(Array)

      args_list.each_slice(safe_limit).with_index.flat_map do |args_batch, index|
        schedule_at_for_batch = process_schedule_at_for_batch(schedule_at, index)

        yield(args_batch, schedule_at_for_batch)
      end
    end

    def process_schedule_at_for_batch(schedule_at, index)
      return unless schedule_at
      return schedule_at[index] if schedule_at.is_a?(Array) && schedule_at.all?(Array)

      schedule_at
    end
  end
end

# frozen_string_literal: true

require 'sidekiq/api'

Sidekiq::Worker.extend ActiveSupport::Concern

module ApplicationWorker
  extend ActiveSupport::Concern

  include Sidekiq::Worker # rubocop:disable Cop/IncludeSidekiqWorker
  include WorkerAttributes
  include WorkerContext
  include Gitlab::SidekiqVersioning::Worker

  LOGGING_EXTRA_KEY = 'extra'

  included do
    set_queue
    after_set_class_attribute { set_queue }

    def structured_payload(payload = {})
      context = Gitlab::ApplicationContext.current.merge(
        'class' => self.class.name,
        'job_status' => 'running',
        'queue' => self.class.queue,
        'jid' => jid
      )

      payload.stringify_keys.merge(context)
    end

    def log_extra_metadata_on_done(key, value)
      @done_log_extra_metadata ||= {}
      @done_log_extra_metadata[key] = value
    end

    def logging_extras
      return {} unless @done_log_extra_metadata

      # Prefix keys with class name to avoid conflicts in Elasticsearch types.
      # Also prefix with "extra." so that we know to log these new fields.
      @done_log_extra_metadata.transform_keys do |k|
        "#{LOGGING_EXTRA_KEY}.#{self.class.name.gsub("::", "_").underscore}.#{k}"
      end
    end
  end

  class_methods do
    def inherited(subclass)
      subclass.set_queue
      subclass.after_set_class_attribute { subclass.set_queue }
    end

    def set_queue
      queue_name = ::Gitlab::SidekiqConfig::WorkerRouter.global.route(self)
      sidekiq_options queue: queue_name # rubocop:disable Cop/SidekiqOptionsQueue
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

    def queue_size
      Sidekiq::Queue.new(queue).size
    end

    def bulk_perform_async(args_list)
      Sidekiq::Client.push_bulk('class' => self, 'args' => args_list)
    end

    def bulk_perform_in(delay, args_list, batch_size: nil, batch_delay: nil)
      now = Time.now.to_i
      schedule = now + delay.to_i

      if schedule <= now
        raise ArgumentError, _('The schedule time must be in the future!')
      end

      if batch_size && batch_delay
        args_list.each_slice(batch_size.to_i).with_index do |args_batch, idx|
          batch_schedule = schedule + idx * batch_delay.to_i
          Sidekiq::Client.push_bulk('class' => self, 'args' => args_batch, 'at' => batch_schedule)
        end
      else
        Sidekiq::Client.push_bulk('class' => self, 'args' => args_list, 'at' => schedule)
      end
    end
  end
end

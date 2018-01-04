Sidekiq::Worker.extend ActiveSupport::Concern

module ApplicationWorker
  extend ActiveSupport::Concern

  include Sidekiq::Worker # rubocop:disable Cop/IncludeSidekiqWorker

  included do
    set_queue
  end

  module ClassMethods
    def inherited(subclass)
      subclass.set_queue
    end

    def set_queue
      queue_name = [queue_namespace, base_queue_name].compact.join(':')

      sidekiq_options queue: queue_name # rubocop:disable Cop/SidekiqOptionsQueue
    end

    def base_queue_name
      name
        .sub(/\AGitlab::/, '')
        .sub(/Worker\z/, '')
        .underscore
        .tr('/', '_')
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

    def bulk_perform_async(args_list)
      Sidekiq::Client.push_bulk('class' => self, 'args' => args_list)
    end

    def bulk_perform_in(delay, args_list)
      now = Time.now.to_i
      schedule = now + delay.to_i

      if schedule <= now
        raise ArgumentError, 'The schedule time must be in the future!'
      end

      Sidekiq::Client.push_bulk('class' => self, 'args' => args_list, 'at' => schedule)
    end
  end
end

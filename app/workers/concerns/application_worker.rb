Sidekiq::Worker.extend ActiveSupport::Concern

module ApplicationWorker
  extend ActiveSupport::Concern

  include Sidekiq::Worker

  included do
    sidekiq_options queue: base_queue_name
  end

  module ClassMethods
    def base_queue_name
      name
        .sub(/\AGitlab::/, '')
        .sub(/Worker\z/, '')
        .underscore
        .tr('/', '_')
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

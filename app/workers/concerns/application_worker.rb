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
  end
end

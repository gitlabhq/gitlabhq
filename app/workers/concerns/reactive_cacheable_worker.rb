# frozen_string_literal: true

module ReactiveCacheableWorker
  extend ActiveSupport::Concern

  included do
    include ApplicationWorker

    sidekiq_options retry: 3

    feature_category_not_owned!
    loggable_arguments 0

    def self.context_for_arguments(arguments)
      class_name, *_other_args = arguments
      Gitlab::ApplicationContext.new(related_class: class_name.to_s)
    end
  end

  def perform(class_name, id, *args)
    klass = begin
      class_name.constantize
    rescue NameError
      nil
    end

    return unless klass

    klass
      .reactive_cache_worker_finder
      .call(id, *args)
      .try(:exclusively_update_reactive_cache!, *args)
  rescue ReactiveCaching::ExceededReactiveCacheLimit => e
    Gitlab::ErrorTracking.track_exception(e)
  end
end

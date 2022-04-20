# frozen_string_literal: true

module ReactiveCacheableWorker
  extend ActiveSupport::Concern

  included do
    include ApplicationWorker

    sidekiq_options retry: 3

    # Feature category is different depending on the model that is using the
    # reactive cache. Identified by the `related_class` attribute.
    feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

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

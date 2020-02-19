# frozen_string_literal: true

class ReactiveCachingWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category_not_owned!

  # TODO: The reactive caching worker should be split into
  # two different workers, one for latency_sensitive jobs without external dependencies
  # and another worker without latency_sensitivity, but with external dependencies
  # https://gitlab.com/gitlab-com/gl-infra/scalability/issues/34
  # This worker should also have `worker_has_external_dependencies!` enabled
  latency_sensitive_worker!
  worker_resource_boundary :cpu

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

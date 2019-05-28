# frozen_string_literal: true

class ReactiveCachingWorker
  include ApplicationWorker

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
  end
end

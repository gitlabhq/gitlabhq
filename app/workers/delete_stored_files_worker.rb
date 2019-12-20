# frozen_string_literal: true

class DeleteStoredFilesWorker
  include ApplicationWorker

  feature_category_not_owned!

  def perform(class_name, keys)
    klass = begin
      class_name.constantize
    rescue NameError
      nil
    end

    unless klass
      message = "Unknown class '#{class_name}'"
      logger.error(message)
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(RuntimeError.new(message))
      return
    end

    klass.new(logger: logger).delete_keys(keys)
  end
end

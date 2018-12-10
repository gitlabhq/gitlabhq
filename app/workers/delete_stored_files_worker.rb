# frozen_string_literal: true

class DeleteStoredFilesWorker
  include ApplicationWorker

  def perform(class_name, keys)
    klass = begin
      class_name.constantize
    rescue NameError
      nil
    end

    unless klass
      message = "Unknown class '#{class_name}'"
      logger.error(message)
      Gitlab::Sentry.track_exception(RuntimeError.new(message))
      return
    end

    klass.new(logger: logger).delete_keys(keys)
  end
end

# frozen_string_literal: true

class DeleteStoredFilesWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category_not_owned!
  loggable_arguments 0

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

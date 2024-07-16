# frozen_string_literal: true

class FileHookWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always
  sidekiq_options retry: false
  feature_category :webhooks
  loggable_arguments 0
  urgency :low

  def perform(file_name, data)
    success, message = Gitlab::FileHook.execute(file_name, data)

    unless success
      Gitlab::FileHookLogger.error("File hook error => #{file_name}: #{message}")
    end

    true
  end
end

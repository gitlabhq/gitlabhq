# frozen_string_literal: true

class FileHookWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: false
  feature_category :integrations
  loggable_arguments 0

  def perform(file_name, data)
    success, message = Gitlab::FileHook.execute(file_name, data)

    unless success
      Gitlab::FileHookLogger.error("File Hook Error => #{file_name}: #{message}")
    end

    true
  end
end

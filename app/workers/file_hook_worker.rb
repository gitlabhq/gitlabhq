# frozen_string_literal: true

class FileHookWorker
  include ApplicationWorker

  sidekiq_options retry: false
  feature_category :integrations

  def perform(file_name, data)
    success, message = Gitlab::FileHook.execute(file_name, data)

    unless success
      Gitlab::FileHookLogger.error("File Hook Error => #{file_name}: #{message}")
    end

    true
  end
end

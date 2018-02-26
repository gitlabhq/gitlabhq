class PluginWorker
  include ApplicationWorker

  sidekiq_options retry: false

  def perform(file_name, data)
    Gitlab::Plugin.execute(file_name, data)
  rescue => e
    Rails.logger.error("#{self.class}: #{e.message}")
  end
end

class PluginWorker
  include ApplicationWorker

  sidekiq_options retry: false

  def perform(file_name, data)
    Gitlab::Plugin.execute(file_name, data)
  end
end

# Make sure we initialize a Gitaly channel before Sidekiq starts multi-threaded execution.
Gitlab.config.repositories.storages.each do |name, params|
  Gitlab::GitalyClient.configure_channel(name, params['socket_path'])
end

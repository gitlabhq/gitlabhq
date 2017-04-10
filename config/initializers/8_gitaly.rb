require 'uri'

# Make sure we initialize our Gitaly channels before Sidekiq starts multi-threaded execution.
if Gitlab.config.gitaly.enabled || Rails.env.test?
  Gitlab::GitalyClient.configure_channels
end

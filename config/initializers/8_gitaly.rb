# Make sure we initialize a Gitaly channel before Sidekiq starts multi-threaded execution.
Gitlab::GitalyClient.channel unless Rails.env.test?

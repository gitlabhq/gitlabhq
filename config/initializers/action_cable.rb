# frozen_string_literal: true

require 'action_cable/subscription_adapter/redis'

Rails.application.configure do
  config.action_cable.mount_path = '/-/cable'

  config.action_cable.url = Gitlab::Utils.append_path(Gitlab.config.gitlab.relative_url_root, '/-/cable')
  config.action_cable.worker_pool_size = Gitlab::ActionCable::Config.worker_pool_size
  if Rails.env.development? || Rails.env.test?
    config.action_cable.allowed_request_origins = [%r{http(s?)://(127\.0\.0\.1|gdk\.test):\d{4}}]
  end
end

ActionCable::SubscriptionAdapter::Base.prepend(Gitlab::Patch::ActionCableSubscriptionAdapterIdentifier)

using_redis_cluster = begin
  Rails.application.config_for(:cable)[:cluster].present?
rescue RuntimeError
  # config/cable.yml does not exist, but that is not the purpose of this check
end

raise "Do not configure cable.yml with a Redis Cluster as ActionCable only works with Redis." if using_redis_cluster

# https://github.com/rails/rails/blob/bb5ac1623e8de08c1b7b62b1368758f0d3bb6379/actioncable/lib/action_cable/subscription_adapter/redis.rb#L18
ActionCable::SubscriptionAdapter::Redis.redis_connector = lambda do |config|
  args = config.except(:adapter, :channel_prefix)
    .merge(custom: { instrumentation_class: "ActionCable" })

  ::Redis.new(args)
end

Gitlab::ActionCable::RequestStoreCallbacks.install
Gitlab::Database::LoadBalancing::ActionCableCallbacks.install

# frozen_string_literal: true

require 'action_cable/subscription_adapter/redis'

Rails.application.configure do
  # Mount the ActionCable engine when in-app mode is enabled
  config.action_cable.mount_path = Gitlab::ActionCable::Config.in_app? ? '/-/cable' : nil

  config.action_cable.url = Gitlab::Utils.append_path(Gitlab.config.gitlab.relative_url_root, '/-/cable')
  config.action_cable.worker_pool_size = Gitlab::ActionCable::Config.worker_pool_size
end

# https://github.com/rails/rails/blob/bb5ac1623e8de08c1b7b62b1368758f0d3bb6379/actioncable/lib/action_cable/subscription_adapter/redis.rb#L18
ActionCable::SubscriptionAdapter::Redis.redis_connector = lambda do |config|
  args = config.except(:adapter, :channel_prefix)
    .merge(instrumentation_class: ::Gitlab::Instrumentation::Redis::ActionCable)

  ::Redis.new(args)
end

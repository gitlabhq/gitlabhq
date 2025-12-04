# frozen_string_literal: true

require 'action_cable/subscription_adapter/redis'

Rails.application.configure do
  config.action_cable.mount_path = '/-/cable'

  config.action_cable.url = Gitlab::Utils.append_path(Gitlab.config.gitlab.relative_url_root, '/-/cable')
  config.action_cable.worker_pool_size = Gitlab::ActionCable::Config.worker_pool_size
  if Rails.env.development? || Rails.env.test?
    config.action_cable.allowed_request_origins = [Gitlab.config.gitlab.url]
    config.action_cable.disable_request_forgery_protection = Gitlab::Utils.to_boolean(
      ENV.fetch('ACTION_CABLE_DISABLE_REQUEST_FORGERY_PROTECTION', false)
    )
  end

  if Gitlab.config.gitlab.action_cable_allowed_origins.present?
    # sanitize URLs
    error_message = 'Invalid URL found in action_cable_allowed_origins configuration. ' \
      'Please fix this in your gitlab.yml before starting GitLab.'

    allowed_origins = Gitlab.config.gitlab.action_cable_allowed_origins.filter_map do |url|
      begin
        uri = URI.parse(url)
        raise error_message unless uri.is_a?(URI::HTTP) && uri.host.present?
      rescue URI::InvalidURIError
        raise error_message
      end

      url.sub(%r{/+$}, '')
    end

    config.action_cable.allowed_request_origins = allowed_origins if allowed_origins.present?
  end
end

ActionCable::SubscriptionAdapter::Base.prepend(Gitlab::Patch::ActionCableSubscriptionAdapterIdentifier)

using_redis_cluster = begin
  Rails.application.config_for(:cable)&.key?(:cluster)
rescue RuntimeError
  # config/cable.yml does not exist, but that is not the purpose of this check
end

raise "Do not configure cable.yml with a Redis Cluster as ActionCable only works with Redis." if using_redis_cluster

# https://github.com/rails/rails/blob/bb5ac1623e8de08c1b7b62b1368758f0d3bb6379/actioncable/lib/action_cable/subscription_adapter/redis.rb#L18
ActionCable::SubscriptionAdapter::Redis.redis_connector = ->(config) do
  args = config.except(:adapter, :channel_prefix)
    .merge(custom: { instrumentation_class: "ActionCable" })

  final_config = Gitlab::Redis::ConfigGenerator.new('ActionCable').generate(args)

  ::Redis.new(final_config)
end

Gitlab::ActionCable::RequestStoreCallbacks.install
Gitlab::Database::LoadBalancing::ActionCableCallbacks.install
Gitlab::ActionCable::IpAddressStateCallback.install

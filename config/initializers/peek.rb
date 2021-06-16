# frozen_string_literal: true

require 'peek/adapters/redis'

Peek::Adapters::Redis.prepend ::Gitlab::PerformanceBar::RedisAdapterWhenPeekEnabled
Peek.singleton_class.prepend ::Gitlab::PerformanceBar::WithTopLevelWarnings

Rails.application.config.peek.adapter = :redis, { client: ::Redis.new(Gitlab::Redis::Cache.params) }

Peek.into Peek::Views::Host
Peek.into Peek::Views::ActiveRecord
Peek.into Peek::Views::Gitaly
Peek.into Peek::Views::RedisDetailed
Peek.into Peek::Views::Elasticsearch
Peek.into Peek::Views::Rugged
Peek.into Peek::Views::ExternalHttp
Peek.into Peek::Views::BulletDetailed if defined?(Bullet)
Peek.into Peek::Views::Memory

Peek.into Peek::Views::Tracing if Labkit::Tracing.tracing_url_enabled?

# Trigger view creation here, since views might be subscribing to Rails notifications
# via setup_subscribers, which is called in the initializer.
# See https://github.com/peek/peek/blob/master/lib/peek/views/view.rb
Peek.views

ActiveSupport::Notifications.subscribe('endpoint_run.grape') do |_name, _start, _finish, _id, payload|
  if request_id = payload[:env]['action_dispatch.request_id']
    Peek.adapter.save(request_id)
  end
end

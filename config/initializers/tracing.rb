# frozen_string_literal: true

if Labkit::Tracing.enabled?
  Rails.application.configure do |config|
    # Rack needs to parse multipart messages before ActionDispatch can filter parameters
    config.middleware.insert_after Rack::MethodOverride, ::Labkit::Tracing::RackMiddleware
  end

  # Instrument external calls
  Labkit::Tracing::ExternalHttp.instrument
  Labkit::Tracing::Redis.instrument if ENV['GITLAB_TRACING_TRACK_REDIS'].present?

  # Instrument Rails
  Labkit::Tracing::Rails::ActiveRecordSubscriber.instrument
  Labkit::Tracing::Rails::ActionViewSubscriber.instrument
  Labkit::Tracing::Rails::ActiveSupportSubscriber.instrument if ENV['GITLAB_TRACING_TRACK_CACHES'].present?

  # In multi-processed clustered architectures (e.g. Puma cluster) don't
  # start tracing until the worker processes are spawned. This works
  # around issues when the opentracing implementation spawns threads
  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    tracer = Labkit::Tracing::Factory.create_tracer(Gitlab.process_name, Labkit::Tracing.connection_string)
    OpenTracing.global_tracer = tracer if tracer
  end
end

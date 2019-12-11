# frozen_string_literal: true

if Labkit::Tracing.enabled?
  Rails.application.configure do |config|
    config.middleware.insert_after Gitlab::Middleware::CorrelationId, ::Labkit::Tracing::RackMiddleware
  end

  # Instrument the Sidekiq client
  Sidekiq.configure_client do |config|
    config.client_middleware do |chain|
      chain.add Labkit::Tracing::Sidekiq::ClientMiddleware
    end
  end

  # Instrument Sidekiq server calls when running Sidekiq server
  if Gitlab::Runtime.sidekiq?
    Sidekiq.configure_server do |config|
      config.server_middleware do |chain|
        chain.add Labkit::Tracing::Sidekiq::ServerMiddleware
      end
    end
  end

  # Instrument Redis
  Labkit::Tracing::Redis.instrument

  # Instrument Rails
  Labkit::Tracing::Rails::ActiveRecordSubscriber.instrument
  Labkit::Tracing::Rails::ActionViewSubscriber.instrument
  Labkit::Tracing::Rails::ActiveSupportSubscriber.instrument

  # In multi-processed clustered architectures (puma, unicorn) don't
  # start tracing until the worker processes are spawned. This works
  # around issues when the opentracing implementation spawns threads
  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    tracer = Labkit::Tracing::Factory.create_tracer(Gitlab.process_name, Labkit::Tracing.connection_string)
    OpenTracing.global_tracer = tracer if tracer
  end
end

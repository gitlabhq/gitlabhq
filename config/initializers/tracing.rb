# frozen_string_literal: true

if Gitlab::Tracing.enabled?
  require 'opentracing'

  Rails.application.configure do |config|
    config.middleware.insert_after Gitlab::Middleware::CorrelationId, ::Gitlab::Tracing::RackMiddleware
  end

  # Instrument the Sidekiq client
  Sidekiq.configure_client do |config|
    config.client_middleware do |chain|
      chain.add Gitlab::Tracing::Sidekiq::ClientMiddleware
    end
  end

  # Instrument Sidekiq server calls when running Sidekiq server
  if Sidekiq.server?
    Sidekiq.configure_server do |config|
      config.server_middleware do |chain|
        chain.add Gitlab::Tracing::Sidekiq::ServerMiddleware
      end
    end
  end

  # In multi-processed clustered architectures (puma, unicorn) don't
  # start tracing until the worker processes are spawned. This works
  # around issues when the opentracing implementation spawns threads
  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    tracer = Gitlab::Tracing::Factory.create_tracer(Gitlab.process_name, Gitlab::Tracing.connection_string)
    OpenTracing.global_tracer = tracer if tracer
  end
end

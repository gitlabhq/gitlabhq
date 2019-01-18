# frozen_string_literal: true

if Gitlab::Tracing.enabled?
  require 'opentracing'

  # In multi-processed clustered architectures (puma, unicorn) don't
  # start tracing until the worker processes are spawned. This works
  # around issues when the opentracing implementation spawns threads
  Gitlab::Cluster::LifecycleEvents.on_worker_start do
    tracer = Gitlab::Tracing::Factory.create_tracer(Gitlab.process_name, Gitlab::Tracing.connection_string)
    OpenTracing.global_tracer = tracer if tracer
  end
end

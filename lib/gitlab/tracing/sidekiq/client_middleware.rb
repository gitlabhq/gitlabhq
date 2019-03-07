# frozen_string_literal: true

require 'opentracing'

module Gitlab
  module Tracing
    module Sidekiq
      class ClientMiddleware
        include SidekiqCommon

        SPAN_KIND = 'client'

        def call(worker_class, job, queue, redis_pool)
          in_tracing_span(
            operation_name: "sidekiq:#{job['class']}",
            tags: tags_from_job(job, SPAN_KIND)) do |span|
            # Inject the details directly into the job
            tracer.inject(span.context, OpenTracing::FORMAT_TEXT_MAP, job)

            yield
          end
        end
      end
    end
  end
end

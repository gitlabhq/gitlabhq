# frozen_string_literal: true

require 'opentracing'

module Gitlab
  module Tracing
    module Sidekiq
      class ServerMiddleware
        include SidekiqCommon

        SPAN_KIND = 'server'

        def call(worker, job, queue)
          context = tracer.extract(OpenTracing::FORMAT_TEXT_MAP, job)

          in_tracing_span(
            operation_name: "sidekiq:#{job['class']}",
            child_of: context,
            tags: tags_from_job(job, SPAN_KIND)) do |span|
            yield
          end
        end
      end
    end
  end
end

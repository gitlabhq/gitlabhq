# frozen_string_literal: true

require 'openssl'

module Gitlab
  module Ci
    # Shared CE module for W3C Trace Context ID derivation.
    #
    # All consumers - observability export, CI variables, and EE job telemetry -
    # must use this module to ensure identical trace_id and span_id values.
    module TraceContext
      TRACE_ID_HEX_LENGTH = 32
      SPAN_ID_HEX_LENGTH = 16

      class << self
        # Deterministic trace ID from the root pipeline's database ID.
        # Matches W3C trace-id format: 32 lowercase hex characters.
        def trace_id_for(root_pipeline_id)
          format("%0#{TRACE_ID_HEX_LENGTH}x", root_pipeline_id)
        end

        # Deterministic span ID for a job.
        # +kind+ disambiguates multiple spans for the same job.
        # Matches W3C parent-id format: 16 lowercase hex characters.
        def span_id_for_job(root_pipeline_id, job_id, kind = :default)
          input = "#{root_pipeline_id}:#{job_id}:#{kind}"
          ::OpenSSL::Digest::SHA256.hexdigest(input)[0, SPAN_ID_HEX_LENGTH]
        end

        # Span ID for a pipeline span (used by PipelineToTraces export).
        def span_id_for_pipeline(root_pipeline_id, pipeline_id)
          input = "pipeline:#{root_pipeline_id}:#{pipeline_id}"
          ::OpenSSL::Digest::SHA256.hexdigest(input)[0, SPAN_ID_HEX_LENGTH]
        end

        # Span ID for a bridge (trigger) job, used to link child pipeline
        # spans to their triggering job.
        def span_id_for_bridge(bridge_id)
          format("%0#{SPAN_ID_HEX_LENGTH}x", bridge_id)
        end

        # Build a W3C traceparent value (version=00, flags=01 sampled).
        def build_traceparent(root_pipeline_id, job_id, kind = :default)
          tid = trace_id_for(root_pipeline_id)
          sid = span_id_for_job(root_pipeline_id, job_id, kind)
          "00-#{tid}-#{sid}-01"
        end
      end
    end
  end
end

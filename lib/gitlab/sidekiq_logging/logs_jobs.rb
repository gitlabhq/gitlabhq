# frozen_string_literal: true

module Gitlab
  module SidekiqLogging
    module LogsJobs
      def base_message(payload)
        "#{payload['class']} JID-#{payload['jid']}"
      end

      # NOTE: Arguments are truncated/stringified in sidekiq_logging/json_formatter.rb
      def parse_job(job)
        # Error information from the previous try is in the payload for
        # displaying in the Sidekiq UI, but is very confusing in logs!
        job = job.except('error_backtrace', 'error_class', 'error_message')
        job['class'] = job.delete('wrapped') if job['wrapped'].present?

        job['job_size_bytes'] = Sidekiq.dump_json(job['args']).bytesize
        job['args'] = ['[COMPRESSED]'] if ::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor.compressed?(job)

        # Add process id params
        job['pid'] = ::Process.pid

        job.delete('args') unless SidekiqLogArguments.enabled?

        job
      end
    end
  end
end

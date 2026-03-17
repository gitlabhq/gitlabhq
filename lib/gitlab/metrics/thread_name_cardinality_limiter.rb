# frozen_string_literal: true

module Gitlab
  module Metrics
    module ThreadNameCardinalityLimiter
      KNOWN_PUMA_THREAD_NAMES = ['puma wrkr check', 'puma srv',
        'puma srv tp reap', 'puma srv tp trim', 'puma stat pld'].freeze

      SIDEKIQ_WORKER_THREAD_NAME = 'sidekiq_worker_thread'
      class << self
        def normalize_thread_name(thread_name)
          thread_name = thread_name.to_s.presence

          if thread_name.presence.nil?
            'unnamed'
          elsif /puma srv tp \d+/.match?(thread_name)
            # These are the puma workers processing requests
            'puma srv tp'
          elsif /worker-\d+/.match?(thread_name)
            # These are Concurrent::ThreadPool workers. They get named <pool-name>-worker-<idx>
            # or worker-<idx> if the pool name is unset
            thread_name.gsub(/-\d+$/, '')
          elsif use_thread_name?(thread_name)
            thread_name
          else
            'unrecognized'
          end
        end

        private

        def use_thread_name?(thread_name)
          thread_name == SIDEKIQ_WORKER_THREAD_NAME ||
            # Samplers defined in `lib/gitlab/metrics/samplers`
            thread_name.ends_with?('sampler') ||
            # Exporters from `lib/gitlab/metrics/exporter`
            thread_name.ends_with?('exporter') ||
            # Background tasks run by lib/gitlab/background_task.rb
            thread_name == 'background_task' ||
            KNOWN_PUMA_THREAD_NAMES.include?(thread_name)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Metrics
    module Samplers
      class ThreadsSampler < BaseSampler
        DEFAULT_SAMPLING_INTERVAL_SECONDS = 5
        KNOWN_PUMA_THREAD_NAMES = ['puma worker check pipe', 'puma server',
                                   'puma threadpool reaper', 'puma threadpool trimmer',
                                   'puma worker check pipe', 'puma stat payload'].freeze

        SIDEKIQ_WORKER_THREAD_NAME = 'sidekiq_worker_thread'

        METRIC_PREFIX = "gitlab_ruby_threads_"

        METRIC_DESCRIPTIONS = {
          max_expected_threads: "Maximum number of threads expected to be running and performing application work",
          running_threads: "Number of running Ruby threads by name"
        }.freeze

        def metrics
          @metrics ||= METRIC_DESCRIPTIONS.each_with_object({}) do |(name, description), result|
            result[name] = ::Gitlab::Metrics.gauge(:"#{METRIC_PREFIX}#{name}", description)
          end
        end

        def sample
          metrics[:max_expected_threads].set({}, Gitlab::Runtime.max_threads)

          threads_by_name.each do |name, threads|
            uses_db, not_using_db = threads.partition { |thread| thread[:uses_db_connection] }

            set_running_threads(name, uses_db_connection: "yes", size: uses_db.size)
            set_running_threads(name, uses_db_connection: "no", size: not_using_db.size)
          end
        end

        private

        def set_running_threads(name, uses_db_connection:, size:)
          metrics[:running_threads].set({ thread_name: name, uses_db_connection: uses_db_connection }, size)
        end

        def threads_by_name
          Thread.list.group_by { |thread| name_for_thread(thread) }
        end

        def uses_db_connection(thread)
          thread[:uses_db_connection] ? "yes" : "no"
        end

        def name_for_thread(thread)
          thread_name = thread.name.to_s.presence

          if thread_name.presence.nil?
            'unnamed'
          elsif /puma threadpool \d+/.match?(thread_name)
            # These are the puma workers processing requests
            'puma threadpool'
          elsif use_thread_name?(thread_name)
            thread_name
          else
            'unrecognized'
          end
        end

        def use_thread_name?(thread_name)
          thread_name == SIDEKIQ_WORKER_THREAD_NAME ||
            # Samplers defined in `lib/gitlab/metrics/samplers`
            thread_name.ends_with?('sampler') ||
            # Exporters from `lib/gitlab/metrics/exporter`
            thread_name.ends_with?('exporter') ||
            KNOWN_PUMA_THREAD_NAMES.include?(thread_name)
        end
      end
    end
  end
end

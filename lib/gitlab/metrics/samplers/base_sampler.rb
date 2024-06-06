# frozen_string_literal: true

require 'logger'

module Gitlab
  module Metrics
    module Samplers
      class BaseSampler < Daemon
        attr_reader :interval

        # interval - The sampling interval in seconds.
        # warmup   - When true, takes a single sample eagerly before entering the sampling loop.
        #            This can be useful to ensure that all metrics files exist after `start` returns,
        #            since prometheus-client-mmap creates them lazily upon first access.
        def initialize(interval: nil, logger: Logger.new($stdout), warmup: false, **options)
          interval ||= ENV[interval_env_key]&.to_i
          interval ||= self.class::DEFAULT_SAMPLING_INTERVAL_SECONDS
          interval_half = interval.to_f / 2

          @interval = interval
          @interval_steps = (-interval_half..interval_half).step(0.1).to_a

          @logger = logger
          @warmup = warmup

          super(**options)
        end

        def safe_sample
          sample
        rescue StandardError => e
          @logger.warn("#{self.class}: #{e}, stopping")
          stop
        end

        def sample
          raise NotImplementedError
        end

        # Returns the sleep interval with a random adjustment.
        #
        # The random adjustment is put in place to ensure we:
        #
        # 1. Don't generate samples at the exact same interval every time (thus
        #    potentially missing anything that happens in between samples).
        # 2. Don't sample data at the same interval two times in a row.
        def sleep_interval
          while step = @interval_steps.sample
            next if step == @last_step

            @last_step = step

            return @interval + @last_step
          end
        end

        private

        attr_reader :running

        def sampler_class
          self.class.name.demodulize
        end

        def interval_env_key
          "#{sampler_class.underscore.upcase}_INTERVAL_SECONDS"
        end

        def start_working
          @running = true

          safe_sample if @warmup

          true
        end

        def run_thread
          sleep(sleep_interval)
          while running
            wrap_sampler { safe_sample }
            sleep(sleep_interval)
          end
        end

        def wrap_sampler
          # If a separate exporter is run, Rails.application may not be available.
          return yield unless defined?(Rails) && defined?(Rails.application) && Rails.application

          Rails.application.executor.wrap { yield }
        end

        def stop_working
          @running = false
        end
      end
    end
  end
end

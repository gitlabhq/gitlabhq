# frozen_string_literal: true

require 'set'

module Gitlab
  module ErrorTracking
    module Processor
      module SidekiqProcessor
        FILTERED_STRING = '[FILTERED]'

        class << self
          def filter_arguments(args, klass)
            args.lazy.with_index.map do |arg, i|
              case arg
              when Numeric
                arg
              else
                if permitted_arguments_for_worker(klass).include?(i)
                  arg
                else
                  FILTERED_STRING
                end
              end
            end
          end

          def permitted_arguments_for_worker(klass)
            @permitted_arguments_for_worker ||= {}
            @permitted_arguments_for_worker[klass] ||=
              begin
                klass.constantize&.loggable_arguments&.to_set
              rescue StandardError
                Set.new
              end
          end

          def loggable_arguments(args, klass)
            Gitlab::Utils::LogLimitedArray
              .log_limited_array(filter_arguments(args, klass))
              .map(&:to_s)
              .to_a
          end

          def call(event)
            sidekiq = event&.extra&.dig(:sidekiq)

            return event unless sidekiq

            sidekiq = sidekiq.deep_dup
            sidekiq.delete(:jobstr)

            # 'args' in this hash => from Gitlab::ErrorTracking.track_*
            # 'args' in :job => from default error handler
            job_holder = sidekiq.key?('args') ? sidekiq : sidekiq[:job]

            if job_holder['args']
              job_holder['args'] = filter_arguments(job_holder['args'], job_holder['class']).to_a
            end

            event.extra[:sidekiq] = sidekiq

            event
          end
        end
      end
    end
  end
end

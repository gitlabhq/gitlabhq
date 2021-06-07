# frozen_string_literal: true

module Gitlab
  module HealthChecks
    module Redis
      class TraceChunksCheck
        extend SimpleAbstractCheck

        class << self
          def check_up
            check
          end

          private

          def metric_prefix
            'redis_trace_chunks_ping'
          end

          def successful?(result)
            result == 'PONG'
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def check
            catch_timeout 10.seconds do
              Gitlab::Redis::TraceChunks.with(&:ping)
            end
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end

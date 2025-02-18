# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class PatchedFilesMetric < GenericMetric
          value do
            Gitlab::Redis::SharedState.with do |redis|
              redis.get(::Metrics::PatchedFilesWorker::REDIS_KEY)
            end
          end
        end
      end
    end
  end
end

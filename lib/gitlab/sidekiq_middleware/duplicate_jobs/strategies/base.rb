# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      module Strategies
        class Base
          def initialize(duplicate_job)
            @duplicate_job = duplicate_job
          end

          def schedule(job)
            raise NotImplementedError
          end

          def perform(_job)
            raise NotImplementedError
          end

          private

          attr_reader :duplicate_job

          def strategy_name
            self.class.name.to_s.demodulize.underscore.humanize.downcase
          end

          def check!
            # The default expiry time is the worker class'
            # configured deduplication TTL or DuplicateJob::DEFAULT_DUPLICATE_KEY_TTL.
            duplicate_job.check!
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module PauseControl
      module Strategies
        class Base
          extend ::Gitlab::Utils::Override

          def self.should_pause?
            new.should_pause?
          end

          def schedule(job)
            if should_pause?
              pause_job!(job)

              return
            end

            yield
          end

          def perform(job)
            if should_pause?
              pause_job!(job)

              return
            end

            yield
          end

          def should_pause?
            # All children must implement this method
            # return false when the jobs shouldn't be paused and true when it should
            # A cron job PauseControl::ResumeWorker will execute this method to check if jobs should remain paused
            raise NotImplementedError
          end

          private

          def pause_job!(job)
            Gitlab::SidekiqLogging::PauseControlLogger.instance.paused_log(job, strategy: strategy_name)

            Gitlab::SidekiqMiddleware::PauseControl::PauseControlService.add_to_waiting_queue!(
              job['class'],
              job['args'],
              current_context
            )
          end

          def strategy_name
            Gitlab::SidekiqMiddleware::PauseControl::STRATEGIES.key(self.class)
          end

          def current_context
            Gitlab::ApplicationContext.current
          end
        end
      end
    end
  end
end

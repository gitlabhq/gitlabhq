# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      module Handlers
        class SidekiqHandler
          def initialize(shutdown_timeout_seconds, sleep_time_seconds)
            @shutdown_timeout_seconds = shutdown_timeout_seconds
            @sleep_time_seconds = sleep_time_seconds
            @alive = true
          end

          def call
            # Tell Sidekiq to stop fetching new jobs
            # We first SIGNAL and then wait given time
            send_signal(:TSTP, $$, 'stop fetching new jobs', @shutdown_timeout_seconds)
            return true unless @alive

            # Tell sidekiq to restart itself
            # Keep extra safe to wait `Sidekiq.default_configuration[:timeout] + 2` seconds before SIGKILL
            send_signal(:TERM, $$, 'gracefully shut down', Sidekiq.default_configuration[:timeout] + 2)
            return true unless @alive

            # Ideally we should never reach this condition
            # Wait for Sidekiq to shutdown gracefully, and kill it if it didn't
            # If process is group leader, kill the whole pgroup, so we can be sure no children are left behind
            send_signal(:KILL, Process.getpgrp == $$ ? 0 : $$, 'hard shut down')

            true
          end

          def stop
            @alive = false
          end

          private

          def send_signal(signal, pid, explanation, wait_time = nil)
            Sidekiq.logger.warn(
              pid: pid,
              worker_id: ::Prometheus::PidProvider.worker_id,
              memwd_handler_class: self.class.to_s,
              memwd_signal: signal,
              memwd_explanation: explanation,
              memwd_wait_time: wait_time,
              message: "Sending signal and waiting"
            )

            ProcessManagement.signal(pid, signal)

            return unless wait_time

            deadline = Gitlab::Metrics::System.monotonic_time + wait_time

            # Sleep until timeout reached
            sleep(@sleep_time_seconds) while @alive && Gitlab::Metrics::System.monotonic_time < deadline
          end
        end
      end
    end
  end
end

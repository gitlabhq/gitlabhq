# frozen_string_literal: true

module Gitlab
  module Memory
    class Watchdog
      class MonitorState
        class Result
          attr_reader :payload, :monitor_name

          def initialize(strikes_exceeded:, threshold_violated:, monitor_name:, payload:)
            @strikes_exceeded = strikes_exceeded
            @threshold_violated = threshold_violated
            @monitor_name = monitor_name.to_s.to_sym
            @payload = payload
          end

          def strikes_exceeded?
            @strikes_exceeded
          end

          def threshold_violated?
            @threshold_violated
          end
        end

        def initialize(monitor, max_strikes:, monitor_name:)
          @monitor = monitor
          @max_strikes = max_strikes
          @monitor_name = monitor_name
          @strikes = 0
        end

        def call
          reset_strikes if strikes_exceeded?

          monitor_result = @monitor.call

          if monitor_result[:threshold_violated]
            issue_strike
          else
            reset_strikes
          end

          build_result(monitor_result)
        end

        private

        def build_result(monitor_result)
          Result.new(
            strikes_exceeded: strikes_exceeded?,
            monitor_name: @monitor_name,
            threshold_violated: monitor_result[:threshold_violated],
            payload: payload.merge(monitor_result[:payload]))
        end

        def payload
          {
            memwd_max_strikes: @max_strikes,
            memwd_cur_strikes: @strikes
          }
        end

        def strikes_exceeded?
          @strikes > @max_strikes
        end

        def issue_strike
          @strikes += 1
        end

        def reset_strikes
          @strikes = 0
        end
      end
    end
  end
end

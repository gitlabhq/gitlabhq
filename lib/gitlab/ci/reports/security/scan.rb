# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Scan
          attr_accessor :type, :status, :start_time, :end_time, :partial_scan_mode, :git_strategy

          def initialize(params = {})
            @type = params['type']
            @status = params['status']
            @start_time = params['start_time']
            @end_time = params['end_time']
            @partial_scan_mode = params.dig('partial_scan', 'mode')
            @git_strategy = git_strategy_from(params.dig('observability', 'events'))
          end

          def to_hash
            {
              type: type,
              status: status,
              start_time: start_time,
              end_time: end_time
            }.compact
          end

          private

          # The secrets analyzer reports which commits it scanned only in its observability events
          def git_strategy_from(events)
            return unless events.is_a?(Array)

            events.find { |event| event.is_a?(Hash) && event['git_strategy'].present? }&.dig('git_strategy')
          end
        end
      end
    end
  end
end

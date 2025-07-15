# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Scan
          attr_accessor :type, :status, :start_time, :end_time, :partial_scan_mode

          def initialize(params = {})
            @type = params['type']
            @status = params['status']
            @start_time = params['start_time']
            @end_time = params['end_time']
            @partial_scan_mode = params.dig('partial_scan', 'mode')
          end

          def to_hash
            {
              type: type,
              status: status,
              start_time: start_time,
              end_time: end_time
            }.compact
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Scan
          attr_accessor :type, :status, :start_time, :end_time

          def initialize(params = {})
            @type = params.dig('type')
            @status = params.dig('status')
            @start_time = params.dig('start_time')
            @end_time = params.dig('end_time')
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

# frozen_string_literal: true

module Gitlab
  module UsageCounters
    class PodLogs < Common
      def self.base_key
        'POD_LOGS_USAGE_COUNTS'
      end
    end
  end
end

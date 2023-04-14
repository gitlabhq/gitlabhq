# frozen_string_literal: true

module Enums
  module Abuse
    module Source
      def self.sources
        {
          spamcheck: 0,
          virus_total: 1,
          arkose_custom_score: 2,
          arkose_global_score: 3,
          telesign: 4,
          pvs: 5
        }
      end
    end
  end
end

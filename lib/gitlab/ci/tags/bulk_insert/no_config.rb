# frozen_string_literal: true

module Gitlab
  module Ci
    module Tags
      class BulkInsert
        class NoConfig
          def self.build_from(record)
            new(record)
          end

          def initialize(_record = nil); end
        end
      end
    end
  end
end

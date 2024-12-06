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

          def polymorphic_taggings?
            true
          end

          def monomorphic_taggings?(_taggable)
            false
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Stage
        class Factory < Status::Factory
          def self.extended_statuses
            [[Status::SuccessWarning],
             [Status::Stage::PlayManual]]
          end

          def self.common_helpers
            Status::Stage::Common
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Pipeline
        class Factory < Status::Factory
          def self.extended_statuses
            [[Status::SuccessWarning,
              Status::Pipeline::Delayed,
              Status::Pipeline::Blocked]]
          end

          def self.common_helpers
            Status::Pipeline::Common
          end
        end
      end
    end
  end
end

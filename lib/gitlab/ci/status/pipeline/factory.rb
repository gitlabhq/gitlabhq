module Gitlab
  module Ci
    module Status
      module Pipeline
        class Factory < Status::Factory
          def self.extended_statuses
            [Pipeline::SuccessWithWarnings]
          end

          def self.common_helpers
            Status::Pipeline::Common
          end
        end
      end
    end
  end
end

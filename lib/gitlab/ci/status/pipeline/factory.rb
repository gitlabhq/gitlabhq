module Gitlab
  module Ci
    module Status
      module Pipeline
        class Factory < Status::Factory
          private

          def extended_statuses
            [Pipeline::SuccessWithWarnings]
          end

          def core_status
            super.extend(Status::Pipeline::Common)
          end
        end
      end
    end
  end
end

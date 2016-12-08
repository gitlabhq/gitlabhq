module Gitlab
  module Ci
    module Status
      module Build
        class Factory < Status::Factory
          private

          def extended_statuses
            [Stop, Play, Cancelable, Retryable]
          end

          def core_status
            super.extend(Status::Build::Common)
          end
        end
      end
    end
  end
end

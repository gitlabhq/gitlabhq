module Gitlab
  module Ci
    module Status
      module Build
        class Factory < Status::Factory
          private

          def core_status
            super.extend(Status::Build::Common)
          end
        end
      end
    end
  end
end

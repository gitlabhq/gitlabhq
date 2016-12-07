module Gitlab
  module Ci
    module Status
      module Stage
        class Factory < Status::Factory
          private

          def core_status
            super.extend(Status::Stage::Common)
          end
        end
      end
    end
  end
end

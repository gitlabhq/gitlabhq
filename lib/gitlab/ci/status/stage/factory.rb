module Gitlab
  module Ci
    module Status
      module Stage
        class Factory < Status::Factory
          def self.common_helpers
            Status::Stage::Common
          end
        end
      end
    end
  end
end

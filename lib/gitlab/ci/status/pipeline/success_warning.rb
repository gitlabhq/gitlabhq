module Gitlab
  module Ci
    module Status
      module Pipeline
        class SuccessWarning < Status::SuccessWarning
          def self.matches?(pipeline, user)
            pipeline.success? && pipeline.has_warnings?
          end
        end
      end
    end
  end
end

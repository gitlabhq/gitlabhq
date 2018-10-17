module Gitlab
  module Ci
    module Status
      module Deployment
        class Factory < Status::Factory
          def self.extended_statuses
            [[Status::Deployment::Canceled,
              Status::Deployment::Created,
              Status::Deployment::Failed,
              Status::Deployment::Running,
              Status::Deployment::Success]]
          end

          def self.common_helpers
            Status::Deployment::Common
          end
        end
      end
    end
  end
end

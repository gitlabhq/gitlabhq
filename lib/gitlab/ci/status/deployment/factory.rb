module Gitlab
  module Ci
    module Status
      module Deployment
        class Factory < Status::Factory
          def self.extended_statuses
            [[Status::Deployment::Canceled,
              Status::Deployment::Created,
              Status::Deployment::Failed,
              Status::Deployment::Manual,
              Status::Deployment::Pending,
              Status::Deployment::Running,
              Status::Deployment::Scheduled,
              Status::Deployment::Skipped,
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

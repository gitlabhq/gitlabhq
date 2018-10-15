module Gitlab
  module Ci
    module Status
      module Build
        class DeployedFailed < Status::Extended
          def deployment_status
            :failed
          end

          def has_deployments?
            true
          end

          def environment
            subject.persisted_environment
          end

          def self.matches?(build, user)
            build.has_environment? && build.failed?
          end
        end
      end
    end
  end
end

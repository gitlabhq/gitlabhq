module Gitlab
  module Ci
    module Status
      module Build
        class DeployedLatest < Status::Extended
          def deployment_status
            :last
          end

          def has_deployments?
            true
          end

          def environment
            subject.persisted_environment
          end

          def self.matches?(build, user)
            build.has_environment? &&
              build.success? &&
              build.has_latest_deployment?
          end
        end
      end
    end
  end
end

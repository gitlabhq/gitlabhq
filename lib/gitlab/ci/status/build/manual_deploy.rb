module Gitlab
  module Ci
    module Status
      module Build
        class ManualDeploy < Status::Extended
          def deployment_status
            :manual_deploy
          end

          def has_deployments?
            true
          end

          def environment
            subject.persisted_environment
          end

          def self.matches?(build, user)
            build.has_environment? && (build.manual?)
          end
        end
      end
    end
  end
end

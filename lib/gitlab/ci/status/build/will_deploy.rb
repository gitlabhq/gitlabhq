module Gitlab
  module Ci
    module Status
      module Build
        class WillDeploy < Status::Extended
          def deployment_status
            :will_deploy
          end

          def has_deployments?
            true
          end

          def environment
            subject.persisted_environment
          end

          def self.matches?(build, user)
            build.has_environment? && (build.created? || build.pending?)
          end
        end
      end
    end
  end
end

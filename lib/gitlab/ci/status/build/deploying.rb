module Gitlab
  module Ci
    module Status
      module Build
        class Deploying < Status::Extended
          def deployment_status
            :creating
          end

          def has_deployments?
            true
          end

          def environment
            subject.persisted_environment
          end

          def self.matches?(build, user)
            build.has_environment? && build.running?
          end
        end
      end
    end
  end
end

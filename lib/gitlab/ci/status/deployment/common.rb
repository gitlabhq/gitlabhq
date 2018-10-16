module Gitlab
  module Ci
    module Status
      module Deployment
        module Common
          def has_details?
            can?(user, :read_deployment, subject)
          end

          def details_path
            project_job_path(subject.project, subject.deployable)
          end

          def environment_path
            project_environment_path(subject.project, subject.environment)
          end

          def deployment_path
            project_job_path(subject.project, subject.deployable)
          end

          def has_deployment?
            true
          end
        end
      end
    end
  end
end

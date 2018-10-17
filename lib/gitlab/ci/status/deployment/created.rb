module Gitlab
  module Ci
    module Status
      module Deployment
        class Created < Status::Extended
          def environment_text
            if subject.environment.deployments.any?
              "This job will deploy to %{environment_path} and overwrite the %{deployment_path}."
            else
              "This job will deploy to %{environment_path}."
            end
          end

          def deployment_path
            return unless subject.environment.last_deployment

            project_job_path(subject.project, subject.environment.last_deployment.deployable)
          end

          def self.matches?(deployment, user)
            deployment.created?
          end
        end
      end
    end
  end
end

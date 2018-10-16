module Gitlab
  module Ci
    module Status
      module Deployment
        class Success < Status::Extended
          def environment_text
            if subject.last?
<<<<<<< HEAD
              "This job is the most recent deployment to %{environment_path}."
            else
              "This job is an out-of-date deployment to %{environment_path}. View the most recent deployment %{deployment_path}."
            end
          end

          def deployment_path
            project_job_path(subject.project, subject.environment.last_successful_deployment.deployable)
=======
              "This job is the most recent deployment to %{environmentLink}."
            else
              "This job is an out-of-date deployment to %{environmentLink}. View the most recent deployment %{deploymentLink}."
            end
          end

          def deploymentLink
            project_deployment_path(subject.project, subject.environment.last_successful_deployment)
>>>>>>> Use deployment status in job log page
          end

          def self.matches?(deployment, user)
            deployment.success?
          end
        end
      end
    end
  end
end

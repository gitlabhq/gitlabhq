module Gitlab
  module Ci
    module Status
      module Deployment
        class Created < Status::Extended
          def environment_text
            if subject.environment.deployments.any?
              "This job will deploy to %{environmentLink} and overwrite the %{deploymentLink}."
            else
              "This job will deploy to %{environmentLink}."
            end
          end

          def deployment_link
            project_deployment_path(subject.project, subject.environment.last_successful_deployment)
          end

          def self.matches?(deployment, user)
            deployment.created?
          end
        end
      end
    end
  end
end

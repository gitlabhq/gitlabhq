module Gitlab
  module Ci
    module Status
      module Deployment
        module Common
          def has_details?
            can?(current_user, :read_environment, environment) &&
              can?(user, :read_deployment, subject)
          end

          def details_path
            project_job_path(subject.project, subject.deployable)
          end

          def environment_name
            environment.name
          end

          def environment_path
            project_environment_path(subject.project, subject.environment)
          end

          def deployment_path
            project_job_path(subject.project, subject.deployable)
          end

          def external_url
            subject.environment.external_url
          end

          def stop_url
            if can?(current_user, :stop_environment, environment)
              stop_project_environment_path(project, environment)
            end
          end

          def metrics_url
            if environment.has_metrics?
              metrics_project_environment_deployment_path(project, environment, subject)
            end
          end

          def metrics_monitoring_url
            environment_metrics_path(environment)
          end

          def deployed_at
            subject.deployed_at
          end

          def deployed_at_formatted
            subject.deployed_at_formatted
          end

          def environment
            subject.environment
          end
        end
      end
    end
  end
end

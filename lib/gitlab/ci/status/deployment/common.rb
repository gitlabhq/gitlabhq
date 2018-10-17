module Gitlab
  module Ci
    module Status
      module Deployment
        module Common
          def has_details?
            can?(user, :read_environment, environment) &&
              can?(user, :read_deployment, subject)
          end

          def details_path
            project_job_path(project, deployable)
          end

          def environment_name
            environment.name
          end

          def environment_path
            project_environment_path(project, environment)
          end

          def deployment_path
            project_job_path(project, deployable)
          end

          def external_url
            environment.external_url
          end

          def external_url_formatted
            environment.formatted_external_url
          end

          def stop_url
            if can?(user, :stop_environment, environment)
              stop_project_environment_path(project, environment)
            end
          end

          def metrics_url
            if environment.has_metrics?
              metrics_project_environment_deployment_path(project, environment, subject)
            end
          end

          def metrics_monitoring_url
            # environment_metrics_path(environment)
            metrics_project_environment_path(project, environment)
          end

          def deployed_at
            subject.deployed_at
          end

          def deployed_at_formatted
            subject.formatted_deployment_time
          end

          def environment
            subject.environment
          end

          def project
            subject.project
          end

          def deployable
            subject.deployable
          end

          def has_deployment?
            true
          end
        end
      end
    end
  end
end

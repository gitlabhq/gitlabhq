module EE
  module EnvironmentEntity
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      expose :logs_path, if: -> (*) { can_read_pod_logs? } do |environment|
        logs_project_environment_path(environment.project, environment)
      end

      expose :secure_artifacts do
        expose :sast_path, if: -> (*) { environment.last_pipeline&.expose_sast_data? } do |environment|
          raw_project_build_artifacts_url(environment.project,
                                          environment.last_pipeline.sast_artifact,
                                          path: Ci::Build::SAST_FILE)
        end

        expose :dependency_scanning_path, if: -> (*) { environment.last_pipeline&.expose_dependency_scanning_data? } do |environment|
          raw_project_build_artifacts_url(environment.project,
                                          environment.last_pipeline.dependency_scanning_artifact,
                                          path: Ci::Build::DEPENDENCY_SCANNING_FILE)
        end

        expose :dast_path, if: -> (*) { environment.last_pipeline&.expose_dast_data? } do |environment|
          raw_project_build_artifacts_url(environment.project,
                                          environment.last_pipeline.dast_artifact,
                                          path: Ci::Build::DAST_FILE)
        end

        expose :container_scanning_path, if: -> (*) { environment.last_pipeline&.expose_container_scanning_data? } do |environment|
          raw_project_build_artifacts_url(environment.project,
                                          environment.last_pipeline.container_scanning_artifact,
                                          path: Ci::Build::CONTAINER_SCANNING_FILE)
        end
      end
    end

    private

    def can_read_pod_logs?
      can?(current_user, :read_pod_logs, environment.project)
    end
  end
end

module EE
  module API
    module JobArtifacts
      extend ActiveSupport::Concern

      prepended do
        helpers do
          def authorize_download_artifacts!
            super
            check_cross_project_pipelines_feature!
          end

          def check_cross_project_pipelines_feature!
            if job_token_authentication? && !@project.feature_available?(:cross_project_pipelines)
              not_found!('Project')
            end
          end
        end
      end
    end
  end
end

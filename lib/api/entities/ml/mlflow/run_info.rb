# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class RunInfo < Grape::Entity
          include ::API::Helpers::RelatedResourcesHelpers

          expose :run_id
          expose :run_id, as: :run_uuid
          expose(:experiment_id) { |candidate| candidate.experiment.iid.to_s }
          expose(:start_time) { |candidate| candidate.start_time || 0 }
          expose :end_time, expose_nil: false
          expose :name, as: :run_name, expose_nil: false
          expose(:status) { |candidate| candidate.status.to_s.upcase }
          expose :artifact_uri
          expose(:lifecycle_stage) { |candidate| 'active' }
          expose(:user_id) { |candidate| candidate.user_id.to_s }

          private

          CANDIDATE_PREFIX = 'candidate:'

          def run_id
            object.eid.to_s
          end

          def artifact_uri
            uri = if object.package&.generic?
                    generic_package_uri
                  elsif object.model_version_id
                    model_version_uri
                  else
                    ml_model_candidate_uri
                  end

            expose_url(uri)
          end

          # Example: http://127.0.0.1:3000/api/v4/projects/20/packages/ml_models/1/files/
          def model_version_uri
            path = api_v4_projects_packages_ml_models_files___path___path(
              id: object.project.id, model_version_id: object.model_version_id, path: '', file_name: ''
            )

            path.delete_suffix('(/path/)')
          end

          # Example: http://127.0.0.1:3000/api/v4/projects/20/packages/ml_models/1/files/
          def ml_model_candidate_uri
            path = api_v4_projects_packages_ml_models_files___path___path(
              id: object.project.id, model_version_id: "#{CANDIDATE_PREFIX}#{object.iid}", path: '', file_name: ''
            )

            path.delete_suffix('(/path/)')
          end

          # Example: http://127.0.0.1:3000/api/v4/projects/20/packages/generic/ml_experiment_1/1/
          # Note: legacy format
          def generic_package_uri
            path = api_v4_projects_packages_generic_package_version___path___path(
              id: object.project.id, package_name: '', file_name: ''
            )
            path = path.delete_suffix('/package_version/(/path/)')

            [path, object.artifact_root].join('')
          end
        end
      end
    end
  end
end

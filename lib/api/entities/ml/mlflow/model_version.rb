# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class ModelVersion < Grape::Entity
          include ::API::Helpers::RelatedResourcesHelpers

          expose :name, documentation: { type: 'String' }
          expose :version, documentation: { type: 'String' }
          expose :creation_timestamp, documentation: { type: 'Integer' }
          expose :last_updated_timestamp, documentation: { type: 'Integer' }
          expose :user_id, documentation: { type: 'String' }
          expose :current_stage, documentation: { type: 'String', example: 'development' }
          expose :description, documentation: { type: 'String' }
          expose :source, documentation: { type: 'String' }
          expose :run_id, documentation: { type: 'String' }
          expose :status, documentation: { type: 'String', example: 'READY' }
          expose :status_message, documentation: { type: 'String' }
          expose :metadata, as: :tags, using: ::API::Entities::Ml::Mlflow::KeyValue, documentation: { is_array: true }
          expose :run_link, documentation: { type: 'String' }
          expose :aliases, documentation: { is_array: true, type: 'String' }

          private

          def version
            object.id.to_s
          end

          def name
            object.name
          end

          def creation_timestamp
            object.created_at.to_i
          end

          def last_updated_timestamp
            object.updated_at.to_i
          end

          def user_id
            nil
          end

          def current_stage
            "development"
          end

          def description
            object.description.to_s
          end

          def source
            expose_url(Gitlab::Routing.url_helpers.project_ml_model_version_path(
              object.model.project,
              object.model,
              object
            ))
          end

          def run_id
            object.candidate.eid
          end

          def status
            "READY"
          end

          def status_message
            ""
          end

          def run_link
            ""
          end

          def aliases
            [object.version.to_s]
          end
        end
      end
    end
  end
end

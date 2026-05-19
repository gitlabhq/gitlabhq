# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class RegisteredModel < Grape::Entity
          expose :name, documentation: { type: 'String' }
          expose :creation_timestamp, documentation: { type: 'Integer' }
          expose :last_updated_timestamp, documentation: { type: 'Integer' }
          expose :description, documentation: { type: 'String' }
          expose(:user_id, documentation: { type: 'String' }) { |model| model.user_id.to_s }
          expose :metadata, as: :tags, using: ::API::Entities::Ml::Mlflow::KeyValue, documentation: { is_array: true }
          expose :versions, as: :latest_versions, using: ::API::Entities::Ml::Mlflow::ModelVersion, documentation: { is_array: true }

          private

          def creation_timestamp
            object.created_at.to_i
          end

          def last_updated_timestamp
            object.updated_at.to_i
          end

          def description
            object.description.to_s
          end
        end
      end
    end
  end
end

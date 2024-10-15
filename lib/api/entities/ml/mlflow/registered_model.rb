# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class RegisteredModel < Grape::Entity
          expose :name
          expose :creation_timestamp, documentation: { type: Integer }
          expose :last_updated_timestamp, documentation: { type: Integer }
          expose :description
          expose(:user_id) { |model| model.user_id.to_s }
          expose :metadata, as: :tags, using: KeyValue
          expose :versions, as: :latest_versions

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

# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class RegisteredModel < Grape::Entity
          expose :name
          expose :created_at, as: :creation_timestamp
          expose :updated_at, as: :last_updated_timestamp
          expose :description
          expose(:user_id) { |model| model.user_id.to_s }
          expose :metadata, as: :tags, using: KeyValue
        end
      end
    end
  end
end

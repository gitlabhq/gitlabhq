# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        module ModelVersions
          module Responses
            class Update < Grape::Entity
              expose :model_version, with: Types::ModelVersion
            end
          end
        end
      end
    end
  end
end

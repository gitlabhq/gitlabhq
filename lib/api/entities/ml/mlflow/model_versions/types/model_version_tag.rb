# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        module ModelVersions
          module Types
            class ModelVersionTag < Grape::Entity
              expose :key, documentation: { type: 'String' }
              expose :value, documentation: { type: 'String' }
            end
          end
        end
      end
    end
  end
end

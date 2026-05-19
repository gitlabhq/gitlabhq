# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class KeyValue < Grape::Entity
          expose :name, as: :key, documentation: { type: 'String' }
          expose :value, documentation: { type: 'String' }
        end
      end
    end
  end
end

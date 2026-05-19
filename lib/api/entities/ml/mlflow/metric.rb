# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class Metric < Grape::Entity
          expose :name, as: :key, documentation: { type: 'String' }
          expose :value, documentation: { type: 'Float' }
          expose :tracked_at, as: :timestamp, documentation: { type: 'Integer', desc: 'Unix timestamp in milliseconds' }
          expose :step, expose_nil: false, documentation: { type: 'Integer' }
        end
      end
    end
  end
end

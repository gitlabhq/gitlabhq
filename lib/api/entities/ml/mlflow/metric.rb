# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class Metric < Grape::Entity
          expose :name, as: :key
          expose :value
          expose :tracked_at, as: :timestamp
          expose :step, expose_nil: false
        end
      end
    end
  end
end

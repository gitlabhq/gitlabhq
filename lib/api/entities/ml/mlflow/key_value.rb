# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class KeyValue < Grape::Entity
          expose :name, as: :key
          expose :value
        end
      end
    end
  end
end

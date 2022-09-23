# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class RunParam < Grape::Entity
          expose :name, as: :key
          expose :value
        end
      end
    end
  end
end

# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class GetExperiment < Grape::Entity
          expose :itself, using: Experiment, as: :experiment
        end
      end
    end
  end
end

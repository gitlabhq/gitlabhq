# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class ListExperiment < Grape::Entity
          expose :experiments, with: Experiment
        end
      end
    end
  end
end

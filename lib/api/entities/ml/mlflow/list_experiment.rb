# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class ListExperiment < Grape::Entity
          expose :experiments, using: ::API::Entities::Ml::Mlflow::Experiment, documentation: { is_array: true }
        end
      end
    end
  end
end

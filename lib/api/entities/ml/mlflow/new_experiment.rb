# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class NewExperiment < Grape::Entity
          expose :experiment_id

          private

          def experiment_id
            object.iid.to_s
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class Experiment < Grape::Entity
          expose :experiment do
            expose :experiment_id
            expose :name
            expose :lifecycle_stage
            expose :artifact_location
          end

          private

          def lifecycle_stage
            object.deleted_on? ? 'deleted' : 'active'
          end

          def experiment_id
            object.iid.to_s
          end
        end
      end
    end
  end
end

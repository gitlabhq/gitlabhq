# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class Experiment < Grape::Entity
          expose(:experiment_id) { |experiment| experiment.iid.to_s }
          expose :name
          expose(:lifecycle_stage) { |experiment| experiment.deleted_on? ? 'deleted' : 'active' }
          expose(:artifact_location) { |experiment| 'not_implemented' }
        end
      end
    end
  end
end

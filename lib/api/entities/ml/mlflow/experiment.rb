# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class Experiment < Grape::Entity
          expose(:experiment_id, documentation: { type: 'String', example: '1' }) { |experiment| experiment.iid.to_s }
          expose :name, documentation: { type: 'String', example: 'my_experiment' }
          expose(:lifecycle_stage, documentation: { type: 'String', example: 'active' }) do |experiment|
            experiment.deleted_on? ? 'deleted' : 'active'
          end
          expose(:artifact_location, documentation: { type: 'String' }) { |experiment| 'not_implemented' }
          expose :metadata, as: :tags, using: ::API::Entities::Ml::Mlflow::KeyValue, documentation: { is_array: true }
        end
      end
    end
  end
end

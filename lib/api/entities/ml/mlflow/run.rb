# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class Run < Grape::Entity
          expose :itself, using: ::API::Entities::Ml::Mlflow::RunInfo, as: :info
          expose :data, documentation: { type: 'Hash' } do
            expose :latest_metrics, as: :metrics, using: ::API::Entities::Ml::Mlflow::Metric, documentation: { is_array: true }
            expose :params, using: ::API::Entities::Ml::Mlflow::KeyValue, documentation: { is_array: true }
            expose :metadata, as: :tags, using: ::API::Entities::Ml::Mlflow::KeyValue, documentation: { is_array: true }
          end
        end
      end
    end
  end
end

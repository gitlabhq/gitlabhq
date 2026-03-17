# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class GetMetricHistory < Grape::Entity
          expose :metrics, using: ::API::Entities::Ml::Mlflow::Metric, documentation: { is_array: true }
          expose :next_page_token, documentation: { type: 'String' }
        end
      end
    end
  end
end

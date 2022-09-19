# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class Run < Grape::Entity
          expose :run do
            expose(:info) { |candidate| RunInfo.represent(candidate) }
            expose :data do
              expose :metrics, using: Metric
            end
          end
        end
      end
    end
  end
end

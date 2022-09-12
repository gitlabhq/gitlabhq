# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class Run < Grape::Entity
          expose :run do
            expose(:info) { |candidate| RunInfo.represent(candidate) }
            expose(:data) { |candidate| {} }
          end
        end
      end
    end
  end
end

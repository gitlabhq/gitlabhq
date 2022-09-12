# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class UpdateRun < Grape::Entity
          expose :run_info

          private

          def run_info
            ::API::Entities::Ml::Mlflow::RunInfo.represent object
          end
        end
      end
    end
  end
end

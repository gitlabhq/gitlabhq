# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class UpdateRun < Grape::Entity
          expose :itself, using: RunInfo, as: :run_info
        end
      end
    end
  end
end

# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class GetRun < Grape::Entity
          expose :itself, using: ::API::Entities::Ml::Mlflow::Run, as: :run
        end
      end
    end
  end
end

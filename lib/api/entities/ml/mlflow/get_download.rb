# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class GetDownload < Grape::Entity
          expose :artifact_uri, documentation: { type: 'String', desc: 'Download URI for MLflow artifact' }

          private

          def artifact_uri
            "mlflow-artifacts:/#{object}"
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Projects
  module Ml
    module MlflowHelper
      def mlflow_tracking_url(project)
        path = api_v4_projects_ml_mlflow_api_2_0_mlflow_registered_models_create_path(id: project.id)

        path = path.delete_suffix('api/2.0/mlflow/registered-models/create')

        expose_url(path)
      end
    end
  end
end

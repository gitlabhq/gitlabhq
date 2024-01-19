# frozen_string_literal: true

module Projects
  module Ml
    module ModelRegistryHelper
      require 'json'

      def index_ml_model_data(project, user)
        data = {
          projectPath: project.full_path,
          create_model_path: new_project_ml_model_path(project),
          can_write_model_registry: user&.can?(:write_model_registry, project),
          mlflow_tracking_url: mlflow_tracking_url(project)
        }

        Gitlab::Json.generate(data.deep_transform_keys { |k| k.to_s.camelize(:lower) })
      end

      private

      def mlflow_tracking_url(project)
        path = api_v4_projects_ml_mlflow_api_2_0_mlflow_registered_models_create_path(id: project.id)

        path = path.delete_suffix('registered-models/create')

        expose_url(path)
      end
    end
  end
end

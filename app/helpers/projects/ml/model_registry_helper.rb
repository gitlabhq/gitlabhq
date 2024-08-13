# frozen_string_literal: true

module Projects
  module Ml
    module ModelRegistryHelper
      require 'json'

      def index_ml_model_data(project, user)
        data = {
          projectPath: project.full_path,
          create_model_path: new_project_ml_model_path(project),
          can_write_model_registry: can_write_model_registry?(user, project),
          mlflow_tracking_url: mlflow_tracking_url(project),
          max_allowed_file_size: max_allowed_file_size(project),
          markdown_preview_path: ::Gitlab::Routing.url_helpers.project_ml_preview_markdown_url(project)
        }

        to_json(data)
      end

      def show_ml_model_data(model, user)
        project = model.project

        data = {
          projectPath: project.full_path,
          index_models_path: project_ml_models_path(project),
          can_write_model_registry: can_write_model_registry?(user, project),
          mlflow_tracking_url: mlflow_tracking_url(project),
          model_id: model.id,
          model_name: model.name,
          max_allowed_file_size: max_allowed_file_size(project),
          latest_version: model.latest_version&.version,
          markdown_preview_path: ::Gitlab::Routing.url_helpers.project_ml_preview_markdown_url(project)
        }

        to_json(data)
      end

      def show_ml_model_version_data(model_version, user)
        project = model_version.project

        data = {
          project_path: project.full_path,
          model_id: model_version.model.id,
          model_version_id: model_version.id,
          model_name: model_version.name,
          version_name: model_version.version,
          can_write_model_registry: can_write_model_registry?(user, project),
          import_path: model_version_artifact_import_path(project.id, model_version.id),
          model_path: project_ml_model_path(project, model_version.model),
          max_allowed_file_size: max_allowed_file_size(project)
        }

        to_json(data)
      end

      private

      def model_version_artifact_import_path(project_id, model_version_id)
        path = api_v4_projects_packages_ml_models_files___path___path(
          id: project_id, model_version_id: model_version_id, path: '', file_name: ''
        )

        path.delete_suffix('(/path/)')
      end

      def can_write_model_registry?(user, project)
        user&.can?(:write_model_registry, project)
      end

      def max_allowed_file_size(project)
        project.actual_limits.ml_model_max_file_size
      end

      def to_json(data)
        Gitlab::Json.generate(data.deep_transform_keys { |k| k.to_s.camelize(:lower) })
      end

      def mlflow_tracking_url(project)
        path = api_v4_projects_ml_mlflow_api_2_0_mlflow_registered_models_create_path(id: project.id)

        path = path.delete_suffix('api/2.0/mlflow/registered-models/create')

        expose_url(path)
      end
    end
  end
end

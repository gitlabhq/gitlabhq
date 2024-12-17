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
          markdown_preview_path: preview_markdown_path(project)
        }

        to_json(data)
      end

      def new_ml_model_data(project, user)
        data = {
          index_models_path: project_ml_models_path(project),
          projectPath: project.full_path,
          can_write_model_registry: can_write_model_registry?(user, project),
          markdown_preview_path: preview_markdown_path(project)
        }

        to_json(data)
      end

      def show_ml_model_data(model, user)
        project = model.project

        data = {
          projectPath: project.full_path,
          index_models_path: project_ml_models_path(project),
          edit_model_path: edit_project_ml_model_path(project, model.id),
          create_model_version_path: new_project_ml_model_version_path(project, model.id),
          can_write_model_registry: can_write_model_registry?(user, project),
          mlflow_tracking_url: mlflow_tracking_url(project),
          model_id: model.id,
          model_name: model.name,
          max_allowed_file_size: max_allowed_file_size(project),
          latest_version: model.latest_version&.version,
          markdown_preview_path: preview_markdown_path(project)
        }

        to_json(data)
      end

      def edit_ml_model_data(model, user)
        project = model.project

        data = {
          projectPath: project.full_path,
          can_write_model_registry: can_write_model_registry?(user, project),
          markdown_preview_path: preview_markdown_path(project),
          model_path: project_ml_model_path(project, model),
          model_id: model.id,
          model_name: model.name,
          model_description: model.description.to_s
        }

        to_json(data)
      end

      def new_ml_model_version_data(model, user)
        project = model.project

        data = {
          model_path: project_ml_model_path(project, model),
          projectPath: project.full_path,
          can_write_model_registry: can_write_model_registry?(user, project),
          max_allowed_file_size: max_allowed_file_size(project),
          model_gid: model.to_global_id.to_s,
          markdown_preview_path: preview_markdown_path(project)
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
          edit_model_version_path: edit_project_ml_model_version_path(project, model_version.model.id,
            model_version.id),
          max_allowed_file_size: max_allowed_file_size(project),
          markdown_preview_path: preview_markdown_path(project)
        }

        to_json(data)
      end

      def edit_ml_model_version_data(model_version, user)
        project = model_version.project

        data = {
          projectPath: project.full_path,
          can_write_model_registry: can_write_model_registry?(user, project),
          markdown_preview_path: preview_markdown_path(project),
          model_version_path: project_ml_model_version_path(project, model_version.model.id, model_version.id),
          model_gid: model_version.model.to_global_id.to_s,
          model_version_description: model_version.description.to_s,
          model_version_version: model_version.version
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
    end
  end
end

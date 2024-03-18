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
          mlflow_tracking_url: mlflow_tracking_url(project)
        }

        to_json(data)
      end

      def show_ml_model_data(model, user)
        project = model.project
        presenter = model.present

        data = {
          projectPath: project.full_path,
          index_models_path: project_ml_models_path(project),
          can_write_model_registry: can_write_model_registry?(user, project),
          mlflow_tracking_url: mlflow_tracking_url(project),
          model: {
            id: presenter.id,
            name: presenter.name,
            path: presenter.path,
            description: presenter.description,
            latest_version: latest_version_view_model(presenter.latest_version, user),
            version_count: presenter.version_count,
            candidate_count: presenter.candidate_count
          }
        }

        to_json(data)
      end

      private

      def can_write_model_registry?(user, project)
        user&.can?(:write_model_registry, project)
      end

      def to_json(data)
        Gitlab::Json.generate(data.deep_transform_keys { |k| k.to_s.camelize(:lower) })
      end

      def mlflow_tracking_url(project)
        path = api_v4_projects_ml_mlflow_api_2_0_mlflow_registered_models_create_path(id: project.id)

        path = path.delete_suffix('api/2.0/mlflow/registered-models/create')

        expose_url(path)
      end

      def latest_version_view_model(model_version, user)
        return unless model_version

        presenter = model_version.present

        {
          version: presenter.version,
          description: presenter.description,
          path: presenter.path,
          project_path: project_path(presenter.project),
          package_id: presenter.package_id,
          **::Ml::CandidateDetailsPresenter.new(presenter.candidate, user).present
        }
      end
    end
  end
end

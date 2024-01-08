# frozen_string_literal: true

module Projects
  module Ml
    class ModelsIndexComponent < ViewComponent::Base
      include Rails.application.routes.url_helpers
      include API::Helpers::RelatedResourcesHelpers

      attr_reader :paginator, :model_count, :project, :user

      def initialize(project:, current_user:, paginator:, model_count:)
        @project = project
        @paginator = paginator
        @model_count = model_count
        @user = current_user
      end

      private

      def view_model
        vm = {
          models: models_view_model,
          page_info: page_info_view_model,
          model_count: model_count,
          create_model_path: create_model_path,
          can_write_model_registry: user.can?(:write_model_registry, project),
          mlflow_tracking_url: mlflow_tracking_url
        }

        Gitlab::Json.generate(vm.deep_transform_keys { |k| k.to_s.camelize(:lower) })
      end

      def models_view_model
        paginator.records.map(&:present).map do |m|
          {
            name: m.name,
            path: m.path,
            version: m.latest_version_name,
            version_count: m.version_count,
            version_package_path: m.latest_package_path,
            version_path: m.latest_version_path
          }
        end
      end

      def create_model_path
        new_project_ml_model_path(project)
      end

      def page_info_view_model
        {
          has_next_page: paginator.has_next_page?,
          has_previous_page: paginator.has_previous_page?,
          start_cursor: paginator.cursor_for_previous_page,
          end_cursor: paginator.cursor_for_next_page
        }
      end

      def mlflow_tracking_url
        path = api_v4_projects_ml_mlflow_api_2_0_mlflow_registered_models_create_path(id: project.id)

        path = path.delete_suffix('registered-models/create')

        expose_url(path)
      end
    end
  end
end

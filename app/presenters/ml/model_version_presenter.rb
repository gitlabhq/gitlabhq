# frozen_string_literal: true

module Ml
  class ModelVersionPresenter < Gitlab::View::Presenter::Delegated
    include ::API::Helpers::RelatedResourcesHelpers

    presents ::Ml::ModelVersion, as: :model_version

    def display_name
      "#{model_version.model.name} / #{model_version.version}"
    end

    def author
      model_version.package&.creator
    end

    def path
      project_ml_model_version_path(
        model_version.model.project,
        model_version.model,
        model_version
      )
    end

    def package_path
      return unless model_version.package_id.present?

      project_package_path(model_version.project, model_version.package_id)
    end

    def import_path
      return unless model_version.package_id.present?

      path = api_v4_projects_packages_ml_models_files___path___path(
        id: model_version.project_id, model_version_id: model_version.id, path: '', file_name: ''
      )

      path.delete_suffix('(/path/)')
    end

    def artifacts_count
      model_version.package.package_files.length
    end
  end
end

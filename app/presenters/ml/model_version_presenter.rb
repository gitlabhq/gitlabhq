# frozen_string_literal: true

module Ml
  class ModelVersionPresenter < Gitlab::View::Presenter::Delegated
    presents ::Ml::ModelVersion, as: :model_version

    def display_name
      "#{model_version.model.name} / #{model_version.version}"
    end

    def path
      Gitlab::Routing.url_helpers.project_ml_model_version_path(
        model_version.model.project,
        model_version.model,
        model_version
      )
    end
  end
end

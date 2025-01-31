# frozen_string_literal: true

module Ml
  class ModelPresenter < Gitlab::View::Presenter::Delegated
    presents ::Ml::Model, as: :model

    def latest_version_name
      latest_version&.version
    end

    def author
      model.user
    end

    def version_count
      return model.version_count if model.respond_to?(:version_count)

      model.versions.size
    end

    def candidate_count
      model.candidates.size
    end

    def latest_package_path
      latest_version&.package_path
    end

    def latest_version_path
      latest_version&.path
    end

    def path
      project_ml_model_path(model.project, model.id)
    end

    def default_experiment_path
      project_ml_experiment_path(model.project, model.default_experiment.iid)
    end

    private

    def latest_version
      model.latest_version&.present
    end
  end
end

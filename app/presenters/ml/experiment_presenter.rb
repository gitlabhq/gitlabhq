# frozen_string_literal: true

module Ml
  class ExperimentPresenter < Gitlab::View::Presenter::Delegated
    presents ::Ml::Experiment, as: :experiment
    include Rails.application.routes.url_helpers

    def path
      project_ml_experiment_path(experiment.project, experiment)
    end

    def candidate_count
      return experiment.candidate_count if experiment.respond_to?(:candidate_count)

      experiment.candidates.size
    end

    def creator
      experiment.user
    end
  end
end

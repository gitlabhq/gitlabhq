# frozen_string_literal: true

module Ml
  class ExperimentPresenter < Gitlab::View::Presenter::Delegated
    presents ::Ml::Experiment, as: :experiment

    def path
      project_ml_experiment_path(experiment.project, experiment.iid)
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

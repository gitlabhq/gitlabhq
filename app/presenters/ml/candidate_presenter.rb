# frozen_string_literal: true

module Ml
  class CandidatePresenter < Gitlab::View::Presenter::Delegated
    presents ::Ml::Candidate, as: :candidate

    def path
      project_ml_candidate_path(
        candidate.project,
        candidate.iid
      )
    end

    def artifact_path
      return unless candidate.package_id.present?

      project_package_path(candidate.project, candidate.package_id)
    end
  end
end

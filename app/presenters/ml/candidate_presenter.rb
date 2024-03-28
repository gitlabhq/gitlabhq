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

    def artifact_show_path
      package_id = if candidate.model_version
                     candidate.model_version.package_id
                   else
                     candidate.package_id
                   end

      return unless package_id.present?

      project_package_path(candidate.project, package_id)
    end
  end
end

# frozen_string_literal: true

module Releases
  class EvidencePresenter < Gitlab::View::Presenter::Delegated
    include ActionView::Helpers::UrlHelper

    presents :evidence

    def filepath
      release = evidence.release
      project = release.project

      project_evidence_url(project, release, evidence, format: :json)
    end
  end
end

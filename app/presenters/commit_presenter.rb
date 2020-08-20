# frozen_string_literal: true

class CommitPresenter < Gitlab::View::Presenter::Delegated
  include GlobalID::Identification

  presents :commit

  def status_for(ref)
    return unless can?(current_user, :read_commit_status, commit.project)

    commit.latest_pipeline(ref)&.detailed_status(current_user)
  end

  def any_pipelines?
    return false unless can?(current_user, :read_pipeline, commit.project)

    commit.pipelines.any?
  end

  def signature_html
    return unless commit.has_signature?

    ApplicationController.renderer.render(
      'projects/commit/_signature',
      locals: { signature: commit.signature },
      layout: false,
      formats: [:html]
    )
  end
end

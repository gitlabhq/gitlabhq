# frozen_string_literal: true

class CommitPresenter < Gitlab::View::Presenter::Simple
  presents :commit

  def status_for(ref)
    can?(current_user, :read_commit_status, commit.project) && commit.status(ref)
  end

  def any_pipelines?
    can?(current_user, :read_pipeline, commit.project) && commit.pipelines.any?
  end
end

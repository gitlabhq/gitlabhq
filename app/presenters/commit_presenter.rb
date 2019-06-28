# frozen_string_literal: true

class CommitPresenter < Gitlab::View::Presenter::Delegated
  include GlobalID::Identification

  presents :commit

  def status_for(ref)
    can?(current_user, :read_commit_status, commit.project) && commit.status(ref)
  end

  def any_pipelines?
    can?(current_user, :read_pipeline, commit.project) && commit.pipelines.any?
  end

  def web_url
    Gitlab::UrlBuilder.new(commit).url
  end
end

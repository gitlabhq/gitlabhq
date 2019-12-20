# frozen_string_literal: true

class ReleasePresenter < Gitlab::View::Presenter::Delegated
  include ActionView::Helpers::UrlHelper

  presents :release

  delegate :project, :tag, to: :release

  def commit_path
    return unless release.commit && can_download_code?

    project_commit_path(project, release.commit.id)
  end

  def tag_path
    return unless can_download_code?

    project_tag_path(project, release.tag)
  end

  def merge_requests_url
    return unless release_mr_issue_urls_available?

    project_merge_requests_url(project, params_for_issues_and_mrs)
  end

  def issues_url
    return unless release_mr_issue_urls_available?

    project_issues_url(project, params_for_issues_and_mrs)
  end

  def edit_url
    return unless release_edit_page_available?

    edit_project_release_url(project, release)
  end

  def evidence_file_path
    return unless release.evidence.present?

    evidence_project_release_url(project, tag, format: :json)
  end

  private

  def can_download_code?
    can?(current_user, :download_code, project)
  end

  def params_for_issues_and_mrs
    { scope: 'all', state: 'opened', release_tag: release.tag }
  end

  def release_mr_issue_urls_available?
    ::Feature.enabled?(:release_mr_issue_urls, project)
  end

  def release_edit_page_available?
    can?(current_user, :update_release, release)
  end
end

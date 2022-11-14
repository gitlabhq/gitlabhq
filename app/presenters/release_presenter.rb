# frozen_string_literal: true

class ReleasePresenter < Gitlab::View::Presenter::Delegated
  presents ::Release, as: :release

  def commit_path
    return unless release.commit && can_read_code?

    project_commit_path(project, release.commit.id)
  end

  def tag_path
    return unless can_read_code?

    project_tag_path(project, release.tag)
  end

  def self_url
    project_release_url(project, release)
  end

  def opened_merge_requests_url
    project_merge_requests_url(project, params_for_issues_and_mrs)
  end

  def merged_merge_requests_url
    project_merge_requests_url(project, params_for_issues_and_mrs(state: 'merged'))
  end

  def closed_merge_requests_url
    project_merge_requests_url(project, params_for_issues_and_mrs(state: 'closed'))
  end

  def opened_issues_url
    project_issues_url(project, params_for_issues_and_mrs)
  end

  def closed_issues_url
    project_issues_url(project, params_for_issues_and_mrs(state: 'closed'))
  end

  def edit_url
    return unless release_edit_page_available?

    edit_project_release_url(project, release)
  end

  delegator_override :assets_count
  def assets_count
    if can_read_code?
      release.assets_count
    else
      release.assets_count(except: [:sources])
    end
  end

  delegator_override :name
  def name
    release.name
  end

  def download_url(filepath)
    filepath = filepath.sub(%r{^/}, '') if filepath.start_with?('/')

    downloads_project_release_url(project, release, filepath)
  end

  private

  def can_read_code?
    can?(current_user, :read_code, project)
  end

  def params_for_issues_and_mrs(state: 'opened')
    { scope: 'all', state: state, release_tag: release.tag }
  end

  def release_edit_page_available?
    can?(current_user, :update_release, release)
  end
end

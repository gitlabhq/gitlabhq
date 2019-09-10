# frozen_string_literal: true

module ReleasesHelper
  IMAGE_PATH = 'illustrations/releases.svg'
  DOCUMENTATION_PATH = 'user/project/releases/index'

  def illustration
    image_path(IMAGE_PATH)
  end

  def help_page
    help_page_path(DOCUMENTATION_PATH)
  end

  def url_for_merge_requests
    project_merge_requests_url(@project, params_for_issue_and_mr_paths)
  end

  def url_for_issues
    project_issues_url(@project, params_for_issue_and_mr_paths)
  end

  def data_for_releases_page
    {
      project_id: @project.id,
      illustration_path: illustration,
      documentation_path: help_page,
      merge_requests_url: url_for_merge_requests,
      issues_url: url_for_issues
    }
  end

  private

  def params_for_issue_and_mr_paths
    { scope: 'all', state: 'opened' }
  end
end

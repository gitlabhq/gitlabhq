# frozen_string_literal: true

class Projects::UsageQuotasController < Projects::ApplicationController
  before_action :authorize_admin_project!

  layout "project_settings"

  feature_category :utilization

  def index
    @hide_search_settings = true
    @storage_app_data = {
      project_path: @project.full_path,
      usage_quotas_help_page_path: help_page_path('user/usage_quotas'),
      build_artifacts_help_page_path: help_page_path('ci/pipelines/job_artifacts', anchor: 'when-job-artifacts-are-deleted'),
      packages_help_page_path: help_page_path('user/packages/package_registry/index.md', anchor: 'delete-a-package'),
      repository_help_page_path: help_page_path('user/project/repository/reducing_the_repo_size_using_git'),
      snippets_help_page_path: help_page_path('user/snippets', anchor: 'reduce-snippets-repository-size'),
      wiki_help_page_path: help_page_path('administration/wikis/index.md', anchor: 'reduce-wiki-repository-size')
    }
  end
end

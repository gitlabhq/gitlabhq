# frozen_string_literal: true

class IdeController < ApplicationController
  include WebIdeCSP
  include StaticObjectExternalStorageCSP
  include Gitlab::Utils::StrongMemoize
  include ProductAnalyticsTracking

  before_action :authorize_read_project!, only: [:index]
  before_action :ensure_web_ide_oauth_application!, only: [:index]

  before_action do
    push_frontend_feature_flag(:build_service_proxy)
    push_frontend_feature_flag(:reject_unsigned_commits_by_gitlab)
  end

  feature_category :web_ide

  urgency :low

  track_internal_event :index, name: 'web_ide_viewed'

  def index
    @fork_info = fork_info(project, params[:branch])

    render layout: helpers.use_new_web_ide? ? 'fullscreen' : 'application'
  end

  def oauth_redirect
    return render_404 unless ::Gitlab::WebIde::DefaultOauthApplication.feature_enabled?(current_user)
    # TODO - It's **possible** we end up here and no oauth application has been set up.
    # We need to have better handling of these edge cases. Here's a follow-up issue:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/433322
    return render_404 unless ::Gitlab::WebIde::DefaultOauthApplication.oauth_application

    render layout: 'fullscreen', locals: { minimal: true }
  end

  private

  def authorize_read_project!
    render_404 unless can?(current_user, :read_project, project)
  end

  def ensure_web_ide_oauth_application!
    return unless ::Gitlab::WebIde::DefaultOauthApplication.feature_enabled?(current_user)

    ::Gitlab::WebIde::DefaultOauthApplication.ensure_oauth_application!
  end

  def fork_info(project, branch)
    return if can?(current_user, :push_code, project)

    existing_fork = current_user.fork_of(project)

    if existing_fork
      path = helpers.ide_edit_path(existing_fork, branch, '')
      { ide_path: path }
    elsif can?(current_user, :fork_project, project)
      path = helpers.ide_fork_and_edit_path(project, branch, '', with_notice: false)
      { fork_path: path }
    end
  end

  def project
    strong_memoize(:project) do
      next unless params[:project_id].present?

      Project.find_by_full_path(params[:project_id])
    end
  end

  def tracking_namespace_source
    project.namespace
  end

  def tracking_project_source
    project
  end
end

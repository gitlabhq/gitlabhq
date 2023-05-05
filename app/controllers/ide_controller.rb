# frozen_string_literal: true

class IdeController < ApplicationController
  include WebIdeCSP
  include StaticObjectExternalStorageCSP
  include Gitlab::Utils::StrongMemoize

  before_action :authorize_read_project!

  before_action do
    push_frontend_feature_flag(:build_service_proxy)
    push_frontend_feature_flag(:reject_unsigned_commits_by_gitlab)
  end

  feature_category :web_ide

  urgency :low

  def index
    Gitlab::UsageDataCounters::WebIdeCounter.increment_views_count

    if project
      Gitlab::Tracking.event(self.class.to_s, 'web_ide_views', namespace: project.namespace, user: current_user)
      @fork_info = fork_info(project, params[:branch])
    end

    render layout: 'fullscreen', locals: { minimal: helpers.use_new_web_ide? }
  end

  private

  def authorize_read_project!
    render_404 unless can?(current_user, :read_project, project)
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
end

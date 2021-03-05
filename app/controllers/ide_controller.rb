# frozen_string_literal: true

class IdeController < ApplicationController
  layout 'fullscreen'

  include ClientsidePreviewCSP
  include StaticObjectExternalStorageCSP
  include Gitlab::Utils::StrongMemoize

  before_action do
    push_frontend_feature_flag(:build_service_proxy)
    push_frontend_feature_flag(:schema_linting)
    define_index_vars
  end

  feature_category :web_ide

  def index
    Gitlab::UsageDataCounters::WebIdeCounter.increment_views_count
  end

  private

  def define_index_vars
    return unless project

    @branch = params[:branch]
    @path = params[:path]
    @merge_request = params[:merge_request_id]

    unless can?(current_user, :push_code, project)
      @forked_project = ForkProjectsFinder.new(project, current_user: current_user).execute.first
    end
  end

  def project
    strong_memoize(:project) do
      next unless params[:project_id].present?

      Project.find_by_full_path(params[:project_id])
    end
  end
end

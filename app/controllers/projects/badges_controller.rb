# frozen_string_literal: true

class Projects::BadgesController < Projects::ApplicationController
  layout 'project_settings'
  before_action :authorize_admin_project!, only: [:index]
  before_action :no_cache_headers, only: [:pipeline, :coverage]
  before_action :authorize_read_build!, only: [:pipeline, :coverage]

  feature_category :continuous_integration, [:index, :pipeline]
  feature_category :code_testing, [:coverage]
  feature_category :release_orchestration, [:release]

  def pipeline
    pipeline_status = Gitlab::Ci::Badge::Pipeline::Status
      .new(project, params[:ref], opts: {
        ignore_skipped: params[:ignore_skipped],
        key_text: params[:key_text],
        key_width: params[:key_width]
      })

    render_badge pipeline_status
  end

  def coverage
    coverage_report = Gitlab::Ci::Badge::Coverage::Report
      .new(project, params[:ref], opts: {
        job: params[:job],
        key_text: params[:key_text],
        key_width: params[:key_width],
        min_good: params[:min_good],
        min_acceptable: params[:min_acceptable],
        min_medium: params[:min_medium]
      })

    render_badge coverage_report
  end

  def release
    latest_release = Gitlab::Ci::Badge::Release::LatestRelease
      .new(project, current_user, opts: {
        key_text: params[:key_text],
        key_width: params[:key_width],
        value_width: params[:value_width],
        order_by: params[:order_by]
      })

    render_badge latest_release
  end

  private

  def badge_layout
    case params[:style]
    when 'flat'
      'badge'
    when 'flat-square'
      'badge_flat-square'
    else
      'badge'
    end
  end

  def render_badge(badge)
    respond_to do |format|
      format.html { render_404 }
      format.svg do
        render badge_layout, locals: { badge: badge.template }
      end
    end
  end
end

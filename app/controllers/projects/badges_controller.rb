# frozen_string_literal: true

class Projects::BadgesController < Projects::ApplicationController
  before_action :no_cache_headers, only: [:pipeline, :coverage]
  before_action :authorize_read_build!, only: [:pipeline, :coverage]

  feature_category :continuous_integration, [:pipeline]
  feature_category :groups_and_projects, [:custom]
  feature_category :code_testing, [:coverage]
  feature_category :release_orchestration, [:release]

  def pipeline
    pipeline_status = Gitlab::Ci::Badge::Pipeline::Status
      .new(project, pipeline_badge_params[:ref], opts: {
        ignore_skipped: pipeline_badge_params[:ignore_skipped],
        key_text: pipeline_badge_params[:key_text],
        key_width: pipeline_badge_params[:key_width]
      })

    render_badge pipeline_status
  end

  def coverage
    coverage_report = Gitlab::Ci::Badge::Coverage::Report
      .new(project, coverage_badge_params[:ref], opts: {
        job: coverage_badge_params[:job],
        key_text: coverage_badge_params[:key_text],
        key_width: coverage_badge_params[:key_width],
        min_good: coverage_badge_params[:min_good],
        min_acceptable: coverage_badge_params[:min_acceptable],
        min_medium: coverage_badge_params[:min_medium]
      })

    render_badge coverage_report
  end

  def release
    latest_release = Gitlab::Ci::Badge::Release::LatestRelease
      .new(project, current_user, opts: {
        key_text: release_badge_params[:key_text],
        key_width: release_badge_params[:key_width],
        value_width: release_badge_params[:value_width],
        order_by: release_badge_params[:order_by]
      })

    render_badge latest_release
  end

  def custom
    custom_badge = Gitlab::Ci::Badge::Custom::CustomBadge
      .new(project, opts: {
        key_text: custom_badge_params[:key_text],
        key_width: custom_badge_params[:key_width],
        key_color: custom_badge_params[:key_color],
        value_text: custom_badge_params[:value_text],
        value_width: custom_badge_params[:value_width],
        value_color: custom_badge_params[:value_color]
      })

    render_badge custom_badge
  end

  private

  def pipeline_badge_params
    params.permit(:ref, :ignore_skipped, :key_text, :key_width)
  end

  def coverage_badge_params
    params.permit(:ref, :job, :key_text, :key_width, :min_good, :min_acceptable, :min_medium)
  end

  def release_badge_params
    params.permit(:key_text, :key_width, :value_width, :order_by)
  end

  def custom_badge_params
    params.permit(:key_text, :key_width, :key_color, :value_text, :value_width, :value_color)
  end

  def style_param
    params.permit(:style)[:style]
  end

  def badge_layout
    case style_param
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

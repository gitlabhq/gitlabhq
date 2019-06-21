# frozen_string_literal: true

class Projects::BadgesController < Projects::ApplicationController
  layout 'project_settings'
  before_action :authorize_admin_project!, only: [:index]
  before_action :no_cache_headers, only: [:pipeline, :coverage]
  before_action :authorize_read_build!, only: [:pipeline, :coverage]

  def pipeline
    pipeline_status = Gitlab::Badge::Pipeline::Status
      .new(project, params[:ref])

    render_badge pipeline_status
  end

  def coverage
    coverage_report = Gitlab::Badge::Coverage::Report
      .new(project, params[:ref], params[:job])

    render_badge coverage_report
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

class Projects::BadgesController < Projects::ApplicationController
  layout 'project_settings'
  before_action :authorize_admin_project!, only: [:index]
  before_action :no_cache_headers, except: [:index]

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

  def render_badge(badge)
    respond_to do |format|
      format.html { render_404 }
      format.svg do
        render 'badge', locals: { badge: badge.template }
      end
    end
  end
end

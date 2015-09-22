module Ci
  class ChartsController < Ci::ApplicationController
    before_action :authenticate_user!
    before_action :project
    before_action :authorize_access_project!
    before_action :authorize_manage_project!

    layout 'ci/project'

    def show
      @charts = {}
      @charts[:week] = Ci::Charts::WeekChart.new(@project)
      @charts[:month] = Ci::Charts::MonthChart.new(@project)
      @charts[:year] = Ci::Charts::YearChart.new(@project)
      @charts[:build_times] = Ci::Charts::BuildTime.new(@project)
    end

    protected

    def project
      @project = Ci::Project.find(params[:project_id])
    end
  end
end

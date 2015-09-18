module Ci
  class EventsController < Ci::ApplicationController
    EVENTS_PER_PAGE = 50

    before_action :authenticate_user!
    before_action :project
    before_action :authorize_manage_project!

    layout 'ci/project'

    def index
      @events = project.events.order("created_at DESC").page(params[:page]).per(EVENTS_PER_PAGE)
    end

    private

    def project
      @project ||= Ci::Project.find(params[:project_id])
    end
  end
end

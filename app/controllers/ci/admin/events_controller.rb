module Ci
  class Admin::EventsController < Ci::Admin::ApplicationController
    EVENTS_PER_PAGE = 50

    def index
      @events = Ci::Event.admin.order('created_at DESC').page(params[:page]).per(EVENTS_PER_PAGE)
    end
  end
end

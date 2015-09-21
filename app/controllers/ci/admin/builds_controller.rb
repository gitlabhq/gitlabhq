module Ci
  class Admin::BuildsController < Ci::Admin::ApplicationController
    def index
      @scope = params[:scope]
      @builds = Ci::Build.order('created_at DESC').page(params[:page]).per(30)

      @builds =
        case @scope
        when "pending"
          @builds.pending
        when "running"
          @builds.running
        else
          @builds
        end
    end
  end
end

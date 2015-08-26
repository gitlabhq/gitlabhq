module Ci
  class Admin::BuildsController < Ci::Admin::ApplicationController
    def index
      @scope = params[:scope]
      @builds = Ci::Build.order('created_at DESC').page(params[:page]).per(30)

      if ["pending", "running"].include? @scope
        @builds = @builds.send(@scope)
      end
    end
  end
end

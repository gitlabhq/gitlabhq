class Admin::UserCohortsController < Admin::ApplicationController
  def index
    if ApplicationSetting.current.usage_ping_enabled
      @cohorts = UserCohortsService.new.execute(12)
    end
  end
end

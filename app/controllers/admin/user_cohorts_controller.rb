class Admin::UserCohortsController < Admin::ApplicationController
  def index
    if ApplicationSetting.current.usage_ping_enabled
      @cohorts = Rails.cache.fetch('user_cohorts', expires_in: 1.day) do
        UserCohortsService.new.execute
      end
    end
  end
end

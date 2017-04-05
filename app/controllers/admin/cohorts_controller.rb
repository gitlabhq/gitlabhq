class Admin::CohortsController < Admin::ApplicationController
  def index
    if ApplicationSetting.current.usage_ping_enabled
      @cohorts = Rails.cache.fetch('cohorts', expires_in: 1.day) do
        CohortsService.new.execute
      end
    end
  end
end

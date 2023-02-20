# frozen_string_literal: true

class Projects::ServicePingController < Projects::ApplicationController
  before_action :authenticate_user!

  feature_category :web_ide

  def web_ide_pipelines_count
    Gitlab::UsageDataCounters::WebIdeCounter.increment_pipelines_count

    head(:ok)
  end
end

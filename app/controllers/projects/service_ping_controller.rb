# frozen_string_literal: true

class Projects::ServicePingController < Projects::ApplicationController
  before_action :authenticate_user!

  feature_category :service_ping

  def web_ide_clientside_preview
    return render_404 unless Gitlab::CurrentSettings.web_ide_clientside_preview_enabled?

    Gitlab::UsageDataCounters::WebIdeCounter.increment_previews_count

    head(200)
  end

  def web_ide_pipelines_count
    Gitlab::UsageDataCounters::WebIdeCounter.increment_pipelines_count

    head(200)
  end
end

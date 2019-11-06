# frozen_string_literal: true

class Projects::UsagePingController < Projects::ApplicationController
  before_action :authenticate_user!

  def web_ide_clientside_preview
    return render_404 unless Gitlab::CurrentSettings.web_ide_clientside_preview_enabled?

    Gitlab::UsageDataCounters::WebIdeCounter.increment_previews_count

    head(200)
  end
end

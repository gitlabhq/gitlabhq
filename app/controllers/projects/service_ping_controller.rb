# frozen_string_literal: true

class Projects::ServicePingController < Projects::ApplicationController
  before_action :authenticate_user!

  feature_category :web_ide

  def web_ide_clientside_preview
    return render_404 unless Gitlab::CurrentSettings.web_ide_clientside_preview_enabled?

    Gitlab::UsageDataCounters::WebIdeCounter.increment_previews_count

    head(:ok)
  end

  def web_ide_clientside_preview_success
    return render_404 unless Gitlab::CurrentSettings.web_ide_clientside_preview_enabled?

    Gitlab::UsageDataCounters::WebIdeCounter.increment_previews_success_count
    Gitlab::UsageDataCounters::EditorUniqueCounter.track_live_preview_edit_action(author: current_user,
                                                                                  project: project)

    head(:ok)
  end

  def web_ide_pipelines_count
    Gitlab::UsageDataCounters::WebIdeCounter.increment_pipelines_count

    head(:ok)
  end
end

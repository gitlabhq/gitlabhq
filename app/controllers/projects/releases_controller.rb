# frozen_string_literal: true

class Projects::ReleasesController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!
  before_action :check_releases_page_feature_flag

  def index
  end

  private

  def check_releases_page_feature_flag
    return render_404 unless Feature.enabled?(:releases_page)

    push_frontend_feature_flag(:releases_page)
  end
end

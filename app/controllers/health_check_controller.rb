class HealthCheckController < HealthCheck::HealthCheckController
  before_action :validate_health_check_access!

  protected

  def validate_health_check_access!
    return render_404 unless params[:token].presence && params[:token] == current_application_settings.health_check_access_token
  end

  def render_404
    render file: Rails.root.join("public", "404"), layout: false, status: "404"
  end
end

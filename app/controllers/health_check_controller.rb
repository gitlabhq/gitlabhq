class HealthCheckController < HealthCheck::HealthCheckController
  before_action :validate_health_check_access!

  private

  def validate_health_check_access!
    render_404 unless token_valid?
  end

  def token_valid?
    token = params[:token].presence || request.headers['TOKEN']
    token.present? &&
      ActiveSupport::SecurityUtils.variable_size_secure_compare(
        token,
        current_application_settings.health_check_access_token
      )
  end

  def render_404
    render file: Rails.root.join('public', '404'), layout: false, status: '404'
  end
end

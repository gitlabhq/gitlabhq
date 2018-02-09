module RequiresWhitelistedMonitoringClient
  extend ActiveSupport::Concern

  included do
    before_action :validate_ip_whitelisted_or_valid_token!
  end

  private

  def validate_ip_whitelisted_or_valid_token!
    render_404 unless client_ip_whitelisted? || valid_token?
  end

  def client_ip_whitelisted?
    ip_whitelist.any? { |e| e.include?(Gitlab::RequestContext.client_ip) }
  end

  def ip_whitelist
    @ip_whitelist ||= Settings.monitoring.ip_whitelist.map(&IPAddr.method(:new))
  end

  def valid_token?
    token = params[:token].presence || request.headers['TOKEN']
    token.present? &&
      ActiveSupport::SecurityUtils.variable_size_secure_compare(
        token,
        Gitlab::CurrentSettings.health_check_access_token
      )
  end

  def render_404
    render file: Rails.root.join('public', '404'), layout: false, status: '404'
  end
end

module RequiresWhitelistedMonitoringClient
  extend ActiveSupport::Concern
  included do
    before_action :validate_ip_whitelisted!
  end

  private

  def validate_ip_whitelisted!
    render_404 unless client_ip_whitelisted?
  end

  def client_ip_whitelisted?
    Settings.monitoring.ip_whitelist.any? {|e| e.include?(Gitlab::RequestContext.client_ip) }
  end

  def render_404
    render file: Rails.root.join('public', '404'), layout: false, status: '404'
  end
end

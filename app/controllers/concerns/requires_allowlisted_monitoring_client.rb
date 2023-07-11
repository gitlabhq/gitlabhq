# frozen_string_literal: true

module RequiresAllowlistedMonitoringClient
  extend ActiveSupport::Concern

  included do
    before_action :validate_ip_allowlisted_or_valid_token!
  end

  private

  def validate_ip_allowlisted_or_valid_token!
    render_404 unless client_ip_allowlisted? || valid_token?
  end

  def client_ip_allowlisted?
    # Always allow developers to access http://localhost:3000/-/metrics for
    # debugging purposes
    return true if Rails.env.development? && request.local?

    ip_allowlist.any? { |e| e.include?(Gitlab::RequestContext.instance.client_ip) }
  end

  def ip_allowlist
    @ip_allowlist ||= Settings.monitoring.ip_whitelist.map { |ip| IPAddr.new(ip) }
  end

  def valid_token?
    token = params[:token].presence || request.headers['TOKEN']
    token.present? &&
      ActiveSupport::SecurityUtils.secure_compare(
        token,
        Gitlab::CurrentSettings.health_check_access_token
      )
  end

  def render_404
    render "errors/not_found", layout: "errors", status: :not_found
  end
end

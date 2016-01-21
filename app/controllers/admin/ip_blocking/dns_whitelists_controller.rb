class Admin::IpBlocking::DnsWhitelistsController < Admin::IpBlocking::DnsBaseController

  private

  def model
    DnsIpWhitelist
  end

  def index_path
    admin_ip_blocking_dns_whitelists_path
  end

  def form_namespace
    :dns_ip_whitelist
  end
end

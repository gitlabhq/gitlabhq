class Admin::IpBlocking::DnsBlacklistsController < Admin::IpBlocking::DnsBaseController

  private

  def model
    DnsIpBlacklist
  end

  def index_path
    admin_ip_blocking_dns_blacklists_path
  end

  def form_namespace
    :dns_ip_blacklist
  end
end

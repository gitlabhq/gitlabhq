class Admin::IpBlocking::WhitelistController < Admin::IpBlocking::IpBaseController

  private

  def model
    WhitelistedIp
  end

  def index_path
    admin_ip_blocking_whitelist_index_path
  end

  def form_namespace
    :whitelisted_ip
  end
end

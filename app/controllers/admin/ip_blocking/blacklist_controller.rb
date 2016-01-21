class Admin::IpBlocking::BlacklistController < Admin::IpBlocking::IpBaseController

  private

  def model
    BlacklistedIp
  end

  def index_path
    admin_ip_blocking_blacklist_index_path
  end

  def form_namespace
    :blacklisted_ip
  end
end

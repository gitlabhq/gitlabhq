module Gitlab
  class IpCheck

    def initialize(ip)
      @ip = ip
      @local_ip_searched = false

      application_settings = ApplicationSetting.current
      @ip_blocking_enabled =  application_settings.ip_blocking_enabled
      @dns_whitelist_threshold = application_settings.dns_whitelist_threshold
      @dns_blacklist_threshold = application_settings.dns_whitelist_threshold
    end

    def spam?
      return false unless @ip_blocking_enabled
      return false if whitelisted?
      blacklisted?
    end

    private

    def whitelisted?
      on_local_whitelist? || on_dns_whitelist?
    end

    def on_local_whitelist?
      !local_ip.nil? && local_ip.is_a?(WhitelistedIp)
    end

    def on_dns_whitelist?
      dnswl_check = DNSXLCheck.create_from_list(DnsIpList.whitelist.all)
      dnswl_check.threshold = @dns_whitelist_threshold
      dnswl_check.test(@ip)
    end

    def blacklisted?
      on_local_blacklist? || on_dns_blacklist?
    end

    def on_local_blacklist?
      !local_ip.nil? && local_ip.is_a?(BlacklistedIp)
    end

    def on_dns_blacklist?
      dnsbl_check = DNSXLCheck.create_from_list(DnsIpList.blacklist.all)
      dnsbl_check.threshold = @dns_blacklist_threshold
      dnsbl_check.test(@ip)
    end

    def local_ip
      unless @local_ip_searched
        @local_ip_searched = true
        @local_ip ||= BlockingIp.find_by(ip: @ip)
      end

      @local_ip
    end
  end
end

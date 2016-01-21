module Gitlab
  class IpCheck

    def initialize(ip)
      @ip = ip

      application_settings = ApplicationSetting.current
      @ip_blocking_enabled =  application_settings.ip_blocking_enabled
      @dnsbl_servers_list = application_settings.dnsbl_servers_list
    end

    def spam?
      @ip_blocking_enabled && blacklisted?
    end

    private

    def blacklisted?
      on_dns_blacklist?
    end

    def on_dns_blacklist?
      dnsbl_check = DNSXLCheck.new
      prepare_dnsbl_list(dnsbl_check)
      dnsbl_check.test(@ip)
    end

    def prepare_dnsbl_list(dnsbl_check)
      @dnsbl_servers_list.split(',').map(&:strip).reject(&:empty?).each do |domain|
        dnsbl_check.add_list(domain, 1)
      end
    end
  end
end

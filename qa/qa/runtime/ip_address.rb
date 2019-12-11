# frozen_string_literal: true
require 'socket'

module QA
  module Runtime
    module IPAddress
      include Support::Api
      HostUnreachableError = Class.new(StandardError)

      LOOPBACK_ADDRESS = '127.0.0.1'
      PUBLIC_IP_ADDRESS_API = "https://api.ipify.org"

      def fetch_current_ip_address
        # When running on CI against a live environment such as staging.gitlab.com,
        # we use the public facing IP address
        ip_address = if Env.running_in_ci? && !URI.parse(Scenario.gitlab_address).host.include?('test')
                       response = get(PUBLIC_IP_ADDRESS_API)
                       raise HostUnreachableError, "#{PUBLIC_IP_ADDRESS_API} is unreachable" unless response.code == Support::Api::HTTP_STATUS_OK

                       response.body
                     elsif page.current_host.include?('localhost')
                       LOOPBACK_ADDRESS
                     else
                       Socket.ip_address_list.detect { |intf| intf.ipv4_private? }.ip_address
                     end

        QA::Runtime::Logger.info "Current IP address: #{ip_address}"

        ip_address
      end
    end
  end
end

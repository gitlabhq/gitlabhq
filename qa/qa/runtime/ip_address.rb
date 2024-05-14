# frozen_string_literal: true

require 'socket'

module QA
  module Runtime
    module IPAddress
      include Support::API
      HostUnreachableError = Class.new(StandardError)

      LOOPBACK_ADDRESS = '127.0.0.1'
      PUBLIC_IP_ADDRESS_API = 'https://api.ipify.org'

      def fetch_current_ip_address
        # When running on CI against a live environment such as staging.gitlab.com,
        # we use the public facing IP address
        ip_address = if Env.use_public_ip_api?
                       Logger.debug 'Using public IP address'
                       response = get_public_ip_address

                       unless response.code == Support::API::HTTP_STATUS_OK
                         raise HostUnreachableError, "#{PUBLIC_IP_ADDRESS_API} is unreachable"
                       end

                       response.body
                     elsif page.current_host.include?('localhost')
                       Logger.debug 'Using loopback IP address'
                       LOOPBACK_ADDRESS
                     else
                       Logger.debug 'Using private IP address'
                       Socket.ip_address_list.detect(&:ipv4_private?).ip_address
                     end

        Logger.info "Current IP address: #{ip_address}"
        ip_address
      end

      def get_public_ip_address
        Support::Retrier.retry_on_exception(sleep_interval: 1) do
          get(PUBLIC_IP_ADDRESS_API)
        end
      end
    end
  end
end

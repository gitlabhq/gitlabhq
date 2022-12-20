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
        non_test_host = !URI.parse(Scenario.gitlab_address).host.include?('.test') # rubocop:disable Rails/NegateInclude
        has_no_public_ip = Env.running_in_ci? || Env.use_public_ip_api?

        ip_address = if has_no_public_ip && non_test_host
                       response = get_public_ip_address

                       raise HostUnreachableError, "#{PUBLIC_IP_ADDRESS_API} is unreachable" unless response.code == Support::API::HTTP_STATUS_OK

                       response.body
                     elsif page.current_host.include?('localhost')
                       LOOPBACK_ADDRESS
                     else
                       Socket.ip_address_list.detect { |intf| intf.ipv4_private? }.ip_address
                     end

        QA::Runtime::Logger.info "Current IP address: #{ip_address}"

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

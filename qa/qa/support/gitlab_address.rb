# frozen_string_literal: true

module QA
  module Support
    class GitlabAddress
      class << self
        # Define gitlab address
        #
        # @param [String] address
        # @return [void]
        def define_gitlab_address_attribute!(address = Runtime::Env.gitlab_url)
          return if initialized?

          validate_address(address)

          Runtime::Scenario.define(:gitlab_address, address_with_port(address, with_default_port: false))
          # Define the "About" page as an `about` subdomain.
          # @example
          #   Given *gitlab_address* = 'https://gitlab.com/' #=> https://about.gitlab.com/
          #   Given *gitlab_address* = 'https://staging.gitlab.com/' #=> https://about.staging.gitlab.com/
          #   Given *gitlab_address* = 'http://gitlab-abc123.test/' #=> http://about.gitlab-abc123.test/
          Runtime::Scenario.define(
            :about_address,
            URI(address).then { |uri| "#{uri.scheme}://about.#{host_with_port(address, with_default_port: false)}" }
          )

          @initialized = true
        end

        # Get gitlab address with port and path
        #
        # @param [String] address
        # @param [Boolean] with_default_port keep default port 80 or 443
        # @return [String]
        def address_with_port(address = Runtime::Scenario.gitlab_address, with_default_port: true)
          uri = URI.parse(address)

          "#{uri.scheme}://#{host_with_port(uri, with_default_port: with_default_port)}"
        end

        # Get gitlab host with port and path
        #
        # @param [<String, URI>] address
        # @param [Boolean] with_default_port keep default port 80 or 443
        # @return [String]
        def host_with_port(address = Runtime::Scenario.gitlab_address, with_default_port: true)
          uri = address.is_a?(URI) ? address : URI.parse(address)
          port = !with_default_port && [80, 443].include?(uri.port) ? "" : ":#{uri.port}"

          "#{uri.host}#{port}#{uri.path}"
        end

        private

        # Gitlab address already set up
        #
        # @return [Boolean]
        def initialized?
          @initialized
        end

        # Validate if address is a valid url
        #
        # @param [String] address
        # @return [void]
        def validate_address(address)
          Runtime::Address.valid?(address) || raise(
            ::ArgumentError, "Configured gitlab address is not a valid url: #{address}"
          )
        end
      end
    end
  end
end

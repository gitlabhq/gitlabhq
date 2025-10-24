# frozen_string_literal: true

module QA
  module Support
    class GitlabAddress
      class << self
        # Define gitlab address
        #
        # @param [String] address
        # @return [void]
        def define_gitlab_address_attribute!(address = nil)
          return if initialized?

          address = gitlab_address(address)

          validate_address!(address)

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

        # Get gitlab url value if not set explicitly
        #
        # @param address [String]
        # @return [String]
        def gitlab_address(address)
          return address unless address.nil?

          default_url = Runtime::Env.gitlab_url
          # Don't try to infer url from gitlab.yml if running in CI or explicitly set via variable
          return default_url if Runtime::Env.running_in_ci? || ENV["QA_GITLAB_URL"].present?

          gitlab_yml = File.exist?("../config/gitlab.yml") ? File.read("../config/gitlab.yml") : nil
          return default_url unless gitlab_yml

          gitlab_config = YAML.safe_load(gitlab_yml, aliases: true).dig("production", "gitlab")
          return default_url unless gitlab_config&.fetch("host", nil)

          hostname = gitlab_config["host"]
          scheme = gitlab_config["https"] ? "https" : "http"
          gitlab_url = "#{scheme}://#{hostname}:#{gitlab_config['port'] || 3000}"
          Runtime::Logger.info("Using '#{gitlab_url}' inferred from gitlab.yml as environment url")
          Runtime::Logger.info("Please set it via `QA_GITLAB_URL` variable to use different value")

          gitlab_url
        end

        # Validate if address is a valid url
        #
        # @param [String] address
        # @return [void]
        def validate_address!(address)
          Runtime::Address.valid?(address) || raise(
            ::ArgumentError, "Configured gitlab address is not a valid url: #{address}"
          )
        end
      end
    end
  end
end

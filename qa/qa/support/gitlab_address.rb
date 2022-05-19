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

          Runtime::Scenario.define(:gitlab_address, address)
          # Define the "About" page as an `about` subdomain.
          # @example
          #   Given *gitlab_address* = 'https://gitlab.com/' #=> https://about.gitlab.com/
          #   Given *gitlab_address* = 'https://staging.gitlab.com/' #=> https://about.staging.gitlab.com/
          #   Given *gitlab_address* = 'http://gitlab-abc123.test/' #=> http://about.gitlab-abc123.test/
          Runtime::Scenario.define(:about_address, URI(address).tap { |uri| uri.host = "about.#{uri.host}" }.to_s)

          @initialized = true
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

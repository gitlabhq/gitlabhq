# frozen_string_literal: true

require "nokogiri"

module QA
  module Tools
    # Helper to assert GitLab instance readiness without starting a web browser
    #
    class ReadinessCheck
      include Support::API

      ReadinessCheckError = Class.new(StandardError)

      def self.perform(wait: 60)
        new(wait: wait).perform
      end

      def initialize(wait:)
        @wait = wait
      end

      # Validate gitlab readiness via check for presence of sign-in-form element
      #
      # @return [void]
      def perform
        info("Waiting for Gitlab to become ready!")
        debug("Checking required element presence on sign-in page")

        wait_for_login_page_to_load

        info("Gitlab is ready!")
      rescue StandardError => e
        raise ReadinessCheckError, "#{error_base} Reason: #{e}"
      end

      private

      delegate :debug, :info, to: QA::Runtime::Logger

      attr_reader :wait

      # Sign in page url
      #
      # @return [String]
      def sign_in_url
        @sign_in_url ||= "#{Support::GitlabAddress.address_with_port(with_default_port: false)}/users/sign_in"
      end

      # Error message base
      #
      # @return [String]
      def error_base
        @error_base ||= "Gitlab readiness check failed, valid sign_in page did not appear within #{wait} seconds!"
      end

      # Required elements css selectors
      #
      # @return [Array<String>]
      def elements_css
        @element_css ||= QA::Page::Main::Login.elements.select(&:required?).map(&:selector_css)
      end

      # Check if sign_in page loads with all required elements
      #
      # @return [void]
      def wait_for_login_page_to_load
        return validate_readiness_via_ui! if Runtime::Env.running_on_live_env?

        response = fetch_sign_in_page
        return validate_readiness_via_ui! if cloudflare_response?(response)

        debug("Checking for required elements via api")
        Support::Retrier.retry_on_exception(max_attempts: wait, sleep_interval: 1, log: false) do
          # re-use initial response from cloudflare check
          response ||= fetch_sign_in_page
          validate_readiness_via_api!(response)
        ensure
          response = nil
        end
        debug("Required elements are present!")
      end

      # Check if headless request got blocked by cloudflare
      #
      # @param response [RestClient::Response]
      # @return [Boolean]
      def cloudflare_response?(response)
        return false unless response

        response.headers[:server] == "cloudflare" || response.code == 403
      end

      # Check presence of required elements on sign_in page via UI
      #
      # @return [void]
      def validate_readiness_via_ui!
        debug("Checking for required elements via web browser")
        Capybara.current_session.using_wait_time(wait) { Runtime::Browser.visit(:gitlab, Page::Main::Login) }
        debug("Required elements are present!")
      end

      # Check presence of required elements from headless sign in page request response
      #
      # @param response [RestClient::Response]
      # @return [void]
      def validate_readiness_via_api!(response)
        raise "Failed to obtain valid http response from #{sign_in_url}" unless response
        raise "Got unsucessfull response code from #{sign_in_url}: #{response.code}" unless ok_response?(response)
        raise "Sign in page missing required elements: '#{elements_css}'" unless required_elements_present?(response)
      end

      # Response from sign-in page
      #
      # @return [RestClient::Response]
      def fetch_sign_in_page
        get(sign_in_url)
      rescue StandardError => e
        debug("Error fetching sign-in page: #{e}")
        nil
      end

      # Validate response code is 200
      #
      # @param [RestClient::Response] response
      # @return [Boolean]
      def ok_response?(response)
        response.code == Support::API::HTTP_STATUS_OK
      end

      # Check required elements are present on sign-in page
      #
      # @param [RestClient::Response] response
      # @return [Boolean]
      def required_elements_present?(response)
        doc = Nokogiri::HTML.parse(response.body)

        elements_css.all? { |sel| doc.css(sel).any? }
      end
    end
  end
end

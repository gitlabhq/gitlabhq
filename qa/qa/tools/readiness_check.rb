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
      def url
        @url ||= "#{Support::GitlabAddress.address_with_port(with_default_port: false)}/users/sign_in"
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
        # Do not perform headless request on .com or release environment due to cloudfare
        # TODO: add additional check to detect when environment doesn't allow to check sign in page via headless request
        if Runtime::Env.running_on_live_env?
          debug("Checking for required elements via web browser")
          return Capybara.current_session.using_wait_time(wait) { Runtime::Browser.visit(:gitlab, Page::Main::Login) }
        end

        Support::Retrier.retry_on_exception(max_attempts: wait, sleep_interval: 1, log: false) do
          response = get(url)

          raise "Got unsucessfull response code from #{url}: #{response.code}" unless ok_response?(response)
          raise "Sign in page missing required elements: '#{elements_css}'" unless required_elements_present?(response)
        end
        debug("Required elements are present!")
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

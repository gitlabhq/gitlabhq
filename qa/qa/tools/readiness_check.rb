# frozen_string_literal: true

require "nokogiri"

module QA
  module Tools
    # Helper to assert GitLab instance readiness without starting a web server
    #
    class ReadinessCheck
      include Support::API

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
        error = nil

        info("Waiting for Gitlab to become ready!")
        Support::Retrier.retry_until(max_duration: wait, sleep_interval: 1, raise_on_failure: false, log: false) do
          result = !required_elements_missing?
          error = nil

          result
        rescue StandardError => e
          error = "#{error_base} #{e.message}"

          false
        end
        raise error if error

        info("Gitlab is ready!")
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

      # Check for missing required elements on sign-in page
      #
      # @return [Boolean]
      def required_elements_missing?
        debug("Checking for required element presence on '#{url}'")
        response = get(url)

        unless ok_response?(response)
          msg = "Got unsucessfull response code: #{response.code}"
          debug(msg) && raise(msg)
        end

        unless required_elements_present?(response)
          msg = "Sign in page missing required elements: '#{elements_css}'"
          debug(msg) && raise(msg)
        end

        debug("Required elements are present!")
        false
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

# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Vendor
    module Jenkins
      module Page
        class LastJobConsole < Page::Base
          attr_accessor :job_name

          CONSOLE_OUTPUT_SELECTOR = '.console-output'

          def path
            "/job/#{@job_name}/lastBuild/console"
          end

          def has_successful_build?
            # Retry on errors such as:
            # Selenium::WebDriver::Error::JavascriptError:
            #   javascript error: this.each is not a function
            Support::Retrier.retry_on_exception(reload_page: page, sleep_interval: 1) do
              has_console_output? && console_output.include?('Finished: SUCCESS')
            end
          end

          def no_failed_status_update?
            !console_output.include?('Failed to update Gitlab commit status')
          end

          private

          def has_console_output?
            page.has_selector?(CONSOLE_OUTPUT_SELECTOR, wait: 1)
          end

          def console_output
            page.find(CONSOLE_OUTPUT_SELECTOR).text
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Vendor
    module Jenkins
      module Page
        class LastJobConsole < Page::Base
          attr_accessor :job_name

          def path
            "/job/#{@job_name}/lastBuild/console"
          end

          def has_successful_build?
            # Retry on errors such as:
            # Selenium::WebDriver::Error::JavascriptError:
            #   javascript error: this.each is not a function
            Support::Retrier.retry_on_exception(reload_page: page) do
              page.has_text?('Finished: SUCCESS')
            end
          end

          def no_failed_status_update?
            page.has_no_text?('Failed to update Gitlab commit status')
          end
        end
      end
    end
  end
end

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
            page.has_text?('Finished: SUCCESS')
          end

          def no_failed_status_update?
            page.has_no_text?('Failed to update Gitlab commit status')
          end
        end
      end
    end
  end
end

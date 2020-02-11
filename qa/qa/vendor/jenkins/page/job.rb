# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Vendor
    module Jenkins
      module Page
        class Job < Page::Base
          attr_accessor :job_name

          def path
            "/job/#{@job_name}"
          end

          def has_successful_build?
            page.has_text?("Last successful build")
          end
        end
      end
    end
  end
end

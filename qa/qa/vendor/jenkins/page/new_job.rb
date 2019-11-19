# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Vendor
    module Jenkins
      module Page
        class NewJob < Page::Base
          def initialize
            @path = 'newJob'
          end

          def visit_and_create_new_job_with_name(new_job_name)
            visit!
            set_new_job_name(new_job_name)
            click_free_style_project
            click_ok
          end

          private

          def set_new_job_name(new_job_name)
            fill_in 'name', with: new_job_name
          end

          def click_free_style_project
            find('.hudson_model_FreeStyleProject').click
          end

          def click_ok
            click_on 'OK'
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Vendor
    module Jenkins
      module Page
        class NewCredentials < Page::Base
          def initialize
            @path = 'credentials/store/system/domain/_/newCredentials'
          end

          def visit_and_set_gitlab_api_token(api_token, description)
            visit!
            wait_for_page_to_load
            select_gitlab_api_token
            set_api_token(api_token)
            set_description(description)
            click_ok
          end

          private

          def select_gitlab_api_token
            find('.setting-name', text: "Kind").find(:xpath, "..").find('select').select "GitLab API token"
          end

          def set_api_token(api_token)
            fill_in '_.apiToken', with: api_token
          end

          def set_description(description)
            fill_in '_.description', with: description
          end

          def click_ok
            click_on 'OK'
          end

          def wait_for_page_to_load
            QA::Support::Waiter.wait_until(sleep_interval: 1.0) do
              page.has_css?('.setting-name', text: "Description")
            end
          end
        end
      end
    end
  end
end

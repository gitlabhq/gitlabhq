# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Vendor
    module Jenkins
      module Page
        class Configure < Page::Base
          def initialize
            @path = 'configure'
          end

          def visit_and_setup_gitlab_connection(gitlab_host, token_description)
            visit!
            fill_in '_.name', with: 'GitLab'
            find('.setting-name', text: "Gitlab host URL").find(:xpath, "..").find('input').set gitlab_host

            dropdown_element = find('.setting-name', text: "Credentials").find(:xpath, "..").find('select')

            QA::Support::Retrier.retry_until(raise_on_failure: true) do
              dropdown_element.select "GitLab API token (#{token_description})"
              dropdown_element.value != ''
            end

            yield if block_given?

            click_save
          end

          def click_test_connection
            click_on 'Test Connection'
          end

          def has_success?
            has_css?('div.ok', text: "Success")
          end

          private

          def click_save
            click_on 'Save'
          end
        end
      end
    end
  end
end

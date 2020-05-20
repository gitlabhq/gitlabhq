# frozen_string_literal: true

require 'capybara/dsl'

module QA
  module Vendor
    module Jenkins
      module Page
        class ConfigureJob < Page::Base
          attr_accessor :job_name

          def path
            "/job/#{@job_name}/configure"
          end

          def configure(scm_url:)
            set_git_source_code_management_url(scm_url)
            click_build_when_change_is_pushed_to_gitlab
            set_publish_status_to_gitlab

            Support::Retrier.retry_until(sleep_interval: 0.5) do
              click_save
              wait_for_configuration_to_save
            end
          end

          private

          def set_git_source_code_management_url(repository_url)
            select_git_source_code_management
            set_repository_url(repository_url)
          end

          def click_build_when_change_is_pushed_to_gitlab
            find('label', text: 'Build when a change is pushed to GitLab').find(:xpath, "..").find('input').click
          end

          def set_publish_status_to_gitlab
            click_add_post_build_action
            select_publish_build_status_to_gitlab
          end

          def click_save
            click_on 'Save'
          end

          def select_git_source_code_management
            find('#radio-block-1').click
          end

          def set_repository_url(repository_url)
            find('.setting-name', text: "Repository URL").find(:xpath, "..").find('input').set repository_url
          end

          def click_add_post_build_action
            click_on "Add post-build action"
          end

          def select_publish_build_status_to_gitlab
            click_link "Publish build status to GitLab"
          end

          def wait_for_configuration_to_save
            QA::Support::Waiter.wait_until(max_duration: 10, raise_on_failure: false) do
              !page.current_url.include?(path)
            end
          end
        end
      end
    end
  end
end

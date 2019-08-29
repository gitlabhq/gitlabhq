# frozen_string_literal: true

module QA
  module Page
    module Project
      module Commit
        class Show < Page::Base
          view 'app/views/projects/commit/_commit_box.html.haml' do
            element :options_button
            element :email_patches
            element :plain_diff
            element :commit_sha_content
          end

          def select_email_patches
            click_element :options_button
            click_element :email_patches
          end

          def select_plain_diff
            click_element :options_button
            click_element :plain_diff
          end

          def commit_sha
            find_element(:commit_sha_content).text
          end
        end
      end
    end
  end
end

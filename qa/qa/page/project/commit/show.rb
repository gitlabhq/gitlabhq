# frozen_string_literal: true

module QA
  module Page
    module Project
      module Commit
        class Show < Page::Base
          view 'app/views/projects/commit/_commit_box.html.haml' do
            element :commit_sha_content
          end

          view 'app/assets/javascripts/projects/commit/components/commit_options_dropdown.vue' do
            element :options_button
            element :revert_button
            element :cherry_pick_button
            element :email_patches
            element :plain_diff
          end

          def revert_commit
            click_element(:options_button)
            click_element(:revert_button, Page::Component::CommitModal)
            click_element(:submit_commit_button)
          end

          def cherry_pick_commit
            click_element(:options_button)
            click_element(:cherry_pick_button, Page::Component::CommitModal)
            click_element(:submit_commit_button)
          end

          def select_email_patches
            click_element :options_button
            visit_link_in_element :email_patches
          end

          def select_plain_diff
            click_element :options_button
            visit_link_in_element :plain_diff
          end

          def commit_sha
            find_element(:commit_sha_content).text
          end
        end
      end
    end
  end
end

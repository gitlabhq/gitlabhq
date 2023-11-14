# frozen_string_literal: true

module QA
  module Page
    module Project
      module Commit
        class Show < Page::Base
          view 'app/views/projects/commit/_commit_box.html.haml' do
            element 'commit-sha-content'
          end

          view 'app/assets/javascripts/projects/commit/components/commit_options_dropdown.vue' do
            element 'commit-options-dropdown'
            element 'revert-link'
            element 'cherry-pick-link'
            element 'email-patches-link'
            element 'plain-diff-link'
          end

          def revert_commit
            click_element('commit-options-dropdown')
            click_element('revert-link', Page::Component::CommitModal)
            click_element('submit-commit')
          end

          def cherry_pick_commit
            click_element('commit-options-dropdown')
            click_element('cherry-pick-link', Page::Component::CommitModal)
            click_element('submit-commit')
          end

          def select_email_patches
            click_element 'commit-options-dropdown'
            visit_link_in_element 'email-patches-link'
          end

          def select_plain_diff
            click_element 'commit-options-dropdown'
            visit_link_in_element 'plain-diff-link'
          end

          def commit_sha
            find_element('commit-sha-content').text
          end
        end
      end
    end
  end
end

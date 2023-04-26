# frozen_string_literal: true

module QA
  module Page
    module Project
      module Issue
        class Show < Page::Base
          include Page::Component::Note
          include Page::Component::DesignManagement
          include Page::Component::Issuable::Sidebar
          # We need to check phone_layout? instead of mobile_layout? here
          # since tablets have the regular top navigation bar
          prepend Mobile::Page::Project::Issue::Show if Runtime::Env.phone_layout?

          view 'app/assets/javascripts/issuable/components/related_issuable_item.vue' do
            element :remove_related_issue_button
          end

          view 'app/assets/javascripts/issues/show/components/header_actions.vue' do
            element :close_issue_button
            element :reopen_issue_button
            element :issue_actions_ellipsis_dropdown
            element :delete_issue_button
          end

          view 'app/assets/javascripts/issues/show/components/title.vue' do
            element :title_content, required: true
          end

          view 'app/assets/javascripts/related_issues/components/add_issuable_form.vue' do
            element :add_issue_button
          end

          view 'app/assets/javascripts/related_issues/components/related_issuable_input.vue' do
            element :add_issue_field
          end

          view 'app/assets/javascripts/related_issues/components/related_issues_block.vue' do
            element :related_issues_plus_button
          end

          view 'app/assets/javascripts/related_issues/components/related_issues_list.vue' do
            element :related_issuable_content
            element :related_issues_loading_placeholder
          end

          def relate_issue(issue)
            click_element(:related_issues_plus_button)
            fill_element(:add_issue_field, issue.web_url)
            send_keys_to_element(:add_issue_field, :enter)
          end

          def related_issuable_item
            find_element(:related_issuable_content)
          end

          def wait_for_related_issues_to_load
            has_no_element?(:related_issues_loading_placeholder, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
          end

          def click_remove_related_issue_button
            retry_until(sleep_interval: 5) do
              click_element(:remove_related_issue_button)
              has_no_element?(:remove_related_issue_button, wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
            end
          end

          def click_close_issue_button
            # Click by JS is needed to bypass the Moved MR actions popover
            # Change back to regular click_element when moved_mr_sidebar FF is removed
            # Rollout issue: https://gitlab.com/gitlab-org/gitlab/-/issues/385460
            click_by_javascript(find_element(:close_issue_button))
          end

          def has_reopen_issue_button?
            has_element?(:reopen_issue_button)
          end

          def has_delete_issue_button?
            # Click by JS is needed to bypass the Moved MR actions popover
            # Change back to regular click_element when moved_mr_sidebar FF is removed
            # Rollout issue: https://gitlab.com/gitlab-org/gitlab/-/issues/385460
            click_by_javascript(find('[data-qa-selector="issue_actions_ellipsis_dropdown"] > button'))
            has_element?(:delete_issue_button)
          end

          def delete_issue
            has_delete_issue_button?

            click_element(:delete_issue_button,
                          Page::Modal::DeleteIssue,
                          wait: Support::Repeater::DEFAULT_MAX_WAIT_TIME)

            Page::Modal::DeleteIssue.perform(&:confirm_delete_issue)

            wait_for_requests
          end
        end
      end
    end
  end
end

QA::Page::Project::Issue::Show.prepend_mod_with('Page::Project::Issue::Show', namespace: QA)

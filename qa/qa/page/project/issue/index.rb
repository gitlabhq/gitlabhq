# frozen_string_literal: true

module QA
  module Page
    module Project
      module Issue
        class Index < Page::Base
          view 'app/assets/javascripts/vue_shared/issuable/list/components/issuable_list_root.vue' do
            element :issuable_container
            element :issuable_search_container
          end

          view 'app/assets/javascripts/issuable/components/issue_assignees.vue' do
            element :assignee_link
            element :avatar_counter_content
          end

          view 'app/assets/javascripts/issuable/components/csv_export_modal.vue' do
            element :export_issuable_modal
          end

          view 'app/assets/javascripts/issuable/components/csv_import_export_buttons.vue' do
            element :export_as_csv_button
            element :import_from_jira_link
          end

          view 'app/assets/javascripts/issues/list/components/issues_list_app.vue' do
            element :issues_list_more_actions_dropdown
          end

          view 'app/assets/javascripts/issues/list/components/empty_state_without_any_issues.vue' do
            element :import_issues_dropdown
          end

          view 'app/assets/javascripts/vue_shared/issuable/list/components/issuable_tabs.vue' do
            element :closed_issuables_tab, ':data-qa-selector="`${tab.name}_issuables_tab`"' # rubocop:disable QA/ElementWithPattern
          end

          def avatar_counter
            find_element(:avatar_counter_content)
          end

          def click_issue_link(title)
            click_link(title)
          end

          def click_closed_issues_tab
            click_element(:closed_issuables_tab)
          end

          def click_export_as_csv_button
            click_element(:export_as_csv_button)
          end

          def click_export_issues_button
            click_element(:export_issues_button)
          end

          def click_import_from_jira_link
            click_element(:import_from_jira_link)
          end

          def click_import_issues_dropdown
            # When there are no issues, the image that loads causes the buttons to jump
            has_loaded_all_images?
            click_element(:import_issues_dropdown)
          end

          def click_issues_list_more_actions_dropdown
            click_element(:issues_list_more_actions_dropdown)
          end

          def export_issues_modal
            find_element(:export_issuable_modal)
          end

          def go_to_jira_import_form
            click_import_issues_dropdown
            click_import_from_jira_link
          end

          def has_assignee_link_count?(count)
            all_elements(:assignee_link, count: count)
          end

          def has_issue?(issue)
            has_element? :issuable_container, issuable_title: issue.title
          end

          def has_no_issue?(issue)
            has_no_element? :issuable_container, issuable_title: issue.title
          end
        end
      end
    end
  end
end

QA::Page::Project::Issue::Index.prepend_mod_with('Page::Project::Issue::Index', namespace: QA)

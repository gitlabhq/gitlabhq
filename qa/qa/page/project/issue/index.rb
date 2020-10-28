# frozen_string_literal: true

module QA
  module Page
    module Project
      module Issue
        class Index < Page::Base
          view 'app/assets/javascripts/issues_list/components/issuable.vue' do
            element :issue_container
            element :issue_link
          end

          view 'app/assets/javascripts/vue_shared/components/issue/issue_assignees.vue' do
            element :assignee_link
            element :avatar_counter_content
          end

          view 'app/views/shared/issuable/csv_export/_button.html.haml' do
            element :export_as_csv_button
          end

          view 'app/views/shared/issuable/csv_export/_modal.html.haml' do
            element :export_issues_button
            element :export_issuable_modal
          end

          view 'app/views/projects/issues/import_csv/_button.html.haml' do
            element :import_issues_button
            element :import_from_jira_link
          end

          view 'app/views/shared/issuable/_nav.html.haml' do
            element :closed_issues_link
          end

          def avatar_counter
            find_element(:avatar_counter_content)
          end

          def click_issue_link(title)
            click_link(title)
          end

          def click_closed_issues_link
            click_element :closed_issues_link
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
            click_element(:import_issues_button)
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
            has_element? :issue_container, issue_title: issue.title
          end
        end
      end
    end
  end
end

QA::Page::Project::Issue::Index.prepend_if_ee('QA::EE::Page::Project::Issue::Index')

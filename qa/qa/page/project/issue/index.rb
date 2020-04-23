# frozen_string_literal: true

module QA
  module Page
    module Project
      module Issue
        class Index < Page::Base
          view 'app/helpers/projects_helper.rb' do
            element :assignee_link
          end

          view 'app/views/projects/issues/export_csv/_button.html.haml' do
            element :export_as_csv_button
          end

          view 'app/views/projects/issues/export_csv/_modal.html.haml' do
            element :export_issues_button
            element :export_issues_modal
          end

          view 'app/views/projects/issues/_issue.html.haml' do
            element :issue
            element :issue_link, 'link_to issue.title' # rubocop:disable QA/ElementWithPattern
          end

          view 'app/views/shared/issuable/_assignees.html.haml' do
            element :avatar_counter
          end

          view 'app/views/shared/issuable/_nav.html.haml' do
            element :closed_issues_link
          end

          def avatar_counter
            find_element(:avatar_counter)
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

          def export_issues_modal
            find_element(:export_issues_modal)
          end

          def has_assignee_link_count?(count)
            all_elements(:assignee_link, count: count)
          end

          def has_issue?(issue)
            has_element? :issue, issue_title: issue.title
          end
        end
      end
    end
  end
end

QA::Page::Project::Issue::Index.prepend_if_ee('QA::EE::Page::Project::Issue::Index')

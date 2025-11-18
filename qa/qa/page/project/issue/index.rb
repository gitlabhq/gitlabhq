# frozen_string_literal: true

module QA
  module Page
    module Project
      module Issue
        class Index < Page::Base
          view 'app/assets/javascripts/issuable/components/issue_assignees.vue' do
            element 'assignee-link'
            element 'avatar-counter-content'
          end

          view 'app/assets/javascripts/vue_shared/issuable/list/components/issuable_list_root.vue' do
            element 'issuable-container'
          end

          view 'app/assets/javascripts/vue_shared/issuable/list/components/issuable_tabs.vue' do
            element 'closed-issuables-tab', ':data-testid="`${tab.name}-issuables-tab`"' # rubocop:disable QA/ElementWithPattern
          end

          view 'app/assets/javascripts/work_items/components/work_item_list_actions.vue' do
            element 'export-as-csv-button'
            element 'import-from-jira-link'
            element 'work-items-list-more-actions-dropdown'
          end

          view 'app/assets/javascripts/work_items/components/work_items_csv_export_modal.vue' do
            element 'export-work-items-button'
            element 'export-work-items-modal'
          end

          def avatar_counter
            find_element('avatar-counter-content')
          end

          def click_issue_link(title)
            click_link(title)
          end

          def click_closed_issues_tab
            if has_element?('closed-issuables-tab')
              click_element('closed-issuables-tab')
            else
              # When we no longer use tabs for open/closed/all lists
              click_element('clear-icon')
              click_element('filtered-search-token-segment')

              if has_button?('State')
                click_button('State')
                within('.gl-filtered-search-suggestion-list') do
                  click_button('Closed')
                end
              else
                click_link('State')
                click_link('Closed')
              end

              click_element('search-button')
            end
          end

          def click_export_as_csv_button
            click_element('export-as-csv-button')
          end

          def click_export_issues_button
            click_element('export-work-items-button')
          end

          def click_import_from_jira_link
            click_element('import-from-jira-link')
          end

          def click_work_items_list_more_actions_dropdown
            click_element('work-items-list-more-actions-dropdown')
          end

          def export_issues_modal
            find_element('export-work-items-modal')
          end

          def go_to_jira_import_form
            unless has_element?('import-from-jira-link', wait: 0)
              within_element('work-item-router-view') do
                click_element('work-items-list-more-actions-dropdown')
              end
            end

            click_import_from_jira_link
          end

          def has_assignee_link_count?(count)
            all_elements('assignee-link', count: count)
          end

          def has_issue?(issue)
            has_element? 'issuable-container', issuable_title: issue.title
          end

          def has_no_issue?(issue)
            has_no_element? 'issuable-container', issuable_title: issue.title
          end
        end
      end
    end
  end
end

QA::Page::Project::Issue::Index.prepend_mod_with('Page::Project::Issue::Index', namespace: QA)

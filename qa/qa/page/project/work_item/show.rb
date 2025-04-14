# frozen_string_literal: true

module QA
  module Page
    module Project
      module WorkItem
        class Show < Page::Base
          include Page::Component::WorkItem::Common
          include Page::Component::WorkItem::Note
          include Page::Component::WorkItem::Widgets

          view 'app/assets/javascripts/vue_shared/components/crud_component.vue' do
            element 'crud-loading'
          end

          view 'app/assets/javascripts/work_items/components/shared/work_item_token_input.vue' do
            element 'work-item-token-select-input'
          end

          view 'app/assets/javascripts/work_items/components/shared/work_item_link_child_contents.vue' do
            element 'remove-work-item-link'
          end

          view 'app/assets/javascripts/work_items/components/work_item_actions.vue' do
            element 'work-item-actions-dropdown'
            element 'delete-action'
            element 'state-toggle-action'
          end

          view 'app/assets/javascripts/work_items/components/work_item_description.vue' do
            element 'save-description'
            element 'work-item-description-wrapper'
          end

          view 'app/assets/javascripts/work_items/components/work_item_description_rendered.vue' do
            element 'work-item-description'
          end

          view 'app/assets/javascripts/work_items/components/work_item_detail.vue' do
            element 'work-item-edit-form-button'
          end

          view "app/assets/javascripts/work_items/components/" \
            "work_item_relationships/work_item_add_relationship_form.vue" do
            element 'link-work-item-button'
          end

          view 'app/assets/javascripts/work_items/components/work_item_relationships/work_item_relationships.vue' do
            element 'link-item-add-button'
          end

          view 'app/assets/javascripts/work_items/components/work_item_relationships/work_item_relationship_list.vue' do
            element 'work-item-linked-items-list'
          end

          view 'app/assets/javascripts/work_items/components/work_item_title.vue' do
            element 'work-item-title'
          end

          view 'app/assets/javascripts/work_items_feedback/components/work_item_feedback.vue' do
            element 'work-item-feedback-popover'
          end

          def edit_description(new_description)
            close_new_issue_popover if has_element?('work-item-feedback-popover')
            wait_for_requests

            click_element('work-item-edit-form-button')

            within_element('work-item-description-wrapper') do
              fill_element('markdown-editor-form-field', new_description)
              click_element('save-description')
            end
          end

          def has_description?(description)
            find_element('work-item-description').text.include?(description)
          end

          def has_delete_issue_button?
            open_actions_dropdown

            has_element?('delete-action')
          end

          def has_no_delete_issue_button?
            open_actions_dropdown

            has_no_element?('delete-action')
          end

          def has_issue_title?(title)
            wait_for_requests
            find_element('work-item-title').text.include?(title)
          end

          def close_new_issue_popover
            within_element('work-item-feedback-popover') do
              click_element('close-button')
            end
          end

          def open_actions_dropdown
            close_new_issue_popover if has_element?('work-item-feedback-popover')

            wait_for_requests

            click_element('work-item-actions-dropdown') unless has_element?('state-toggle-action', visible: true)
          end

          def delete_issue
            has_delete_issue_button?

            click_element(
              'delete-action',
              Modal::DeleteWorkItem,
              wait: Support::Repeater::DEFAULT_MAX_WAIT_TIME
            )

            Page::Modal::DeleteWorkItem.perform(&:confirm_delete_work_item)

            wait_for_requests
          end

          def relate_issue(issue)
            click_element('link-item-add-button')
            fill_element('work-item-token-select-input', issue.web_url)
            wait_for_requests
            # Capybara code is used below due to the dropdown being defined in the @gitlab/ui project
            find('.gl-dropdown-item', text: issue.title).click
            click_element('link-work-item-button')
            wait_for_requests
          end

          def related_issuable_item
            find_element('work-item-linked-items-list')
          end

          def click_remove_related_issue_button
            retry_until(sleep_interval: 5) do
              click_element('remove-work-item-link')
              has_no_element?('remove-work-item-link', wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
            end
          end

          def wait_for_child_items_to_load
            has_no_element?('crud-loading', wait: QA::Support::Repeater::DEFAULT_MAX_WAIT_TIME)
          end

          def click_close_issue_button
            open_actions_dropdown
            click_element('state-toggle-action', text: 'Close issue')
          end

          def has_reopen_issue_button?
            open_actions_dropdown
            has_element?('state-toggle-action', text: 'Reopen issue')
          end
        end
      end
    end
  end
end

QA::Page::Project::WorkItem::Show.prepend_mod_with('Page::Project::WorkItem::Show', namespace: QA)

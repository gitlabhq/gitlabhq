# frozen_string_literal: true

module QA
  module Page
    module Component
      module WorkItem
        module Widgets
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/assets/javascripts/work_items/components/shared/work_item_sidebar_widget.vue' do
              element 'edit-button'
            end

            base.view 'app/assets/javascripts/sidebar/components/assignees/assignee_avatar.vue' do
              element 'avatar-image'
            end

            base.view 'app/assets/javascripts/sidebar/components/assignees/uncollapsed_assignee_list.vue' do
              element 'user-list-more-button'
            end

            base.view 'app/assets/javascripts/work_items/components/work_item_assignees.vue' do
              element 'work-item-assignees'
            end

            base.view 'app/assets/javascripts/work_items/components/work_item_milestone.vue' do
              element 'work-item-milestone'
              element 'work-item-milestone-link'
            end

            base.view 'app/assets/javascripts/work_items/components/work_item_labels.vue' do
              element 'work-item-labels'
            end
          end

          def more_assignees_link
            find_element('user-list-more-button')
          end

          def toggle_more_assignees_link
            click_element('user-list-more-button')
          end

          def has_assignee?(username)
            wait_assignees_block_finish_loading do
              has_text?(username)
            end
          end

          def has_no_assignee?(username)
            wait_assignees_block_finish_loading do
              has_no_text?(username)
            end
          end

          def has_avatar_image_count?(count)
            wait_assignees_block_finish_loading do
              all_elements('avatar-image', count: count)
            end
          end

          def wait_assignees_block_finish_loading
            within_element('work-item-assignees') do
              wait_until(reload: false, max_duration: 10, sleep_interval: 1) do
                finished_loading_block?
                yield
              end
            end
          end

          def assign_milestone(milestone)
            wait_milestone_block_finish_loading do
              click_element('edit-button')
              find_element("listbox-item-gid://gitlab/Milestone/#{milestone.id}").click
            end

            wait_until(reload: false) do
              has_element?('work-item-milestone-link', text: milestone.title, wait: 0)
            end
          end

          def has_milestone?(milestone_title)
            wait_milestone_block_finish_loading do
              has_element?('work-item-milestone-link', text: milestone_title)
            end
          end

          def wait_milestone_block_finish_loading
            within_element('work-item-milestone') do
              wait_until(reload: false, max_duration: 10, sleep_interval: 1) do
                finished_loading_block?
                yield
              end
            end
          end

          def wait_label_block_finish_loading
            within_element('work-item-labels') do
              wait_until(reload: false, max_duration: 10, sleep_interval: 1) do
                finished_loading_block?
                yield
              end
            end
          end

          def click_milestone_link
            click_element('work-item-milestone-link')
          end

          def select_labels(labels)
            within_element('work-item-labels') do
              click_element('edit-button')

              labels.each do |label|
                within_element('base-dropdown-menu') do
                  fill_element('input[type=search]', label)
                  find('[data-testid^="listbox-item-"]').click
                end
              end
            end

            click_element('apply-button')
          end

          def select_label(label)
            select_labels([label.title])
          end

          def has_label?(label)
            wait_labels_block_finish_loading do
              has_element?(label)
            end
          end

          def has_no_label?(label)
            wait_labels_block_finish_loading do
              has_no_element?(label)
            end
          end

          def wait_labels_block_finish_loading
            within_element('work-item-labels') do
              wait_until(reload: false, max_duration: 10, sleep_interval: 1) do
                finished_loading_block?
                yield
              end
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module QA
  module Page
    module Component
      module Issuable
        module Sidebar
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.view 'app/assets/javascripts/sidebar/components/assignees/assignee_avatar.vue' do
              element :avatar_image
            end

            base.view 'app/assets/javascripts/sidebar/components/assignees/uncollapsed_assignee_list.vue' do
              element :more_assignees_link
            end

            base.view 'app/assets/javascripts/sidebar/components/reviewers/reviewer_title.vue' do
              element :reviewers_edit_button
            end

            base.view 'app/assets/javascripts/sidebar/components/labels/labels_select_widget/labels_select_root.vue' do
              element :labels_block
            end

            base.view 'app/assets/javascripts/sidebar/components/labels/labels_select_vue/dropdown_contents_labels_view.vue' do
              element :dropdown_input_field
            end

            base.view 'app/assets/javascripts/sidebar/components/labels/labels_select_widget/dropdown_contents.vue' do
              element :labels_dropdown_content
            end

            base.view 'app/assets/javascripts/sidebar/components/labels/labels_select_widget/dropdown_value.vue' do
              element :selected_label_content
            end

            base.view 'app/views/shared/issuable/_sidebar.html.haml' do
              element :assignee_block_container
              element :milestone_block
              element :reviewers_block_container
            end

            base.view 'app/assets/javascripts/sidebar/components/sidebar_dropdown_widget.vue' do
              element :milestone_link, 'data-qa-selector="`${formatIssuableAttribute.snake}_link`"' # rubocop:disable QA/ElementWithPattern
            end

            base.view 'app/assets/javascripts/sidebar/components/sidebar_editable_item.vue' do
              element :edit_link
            end

            base.view 'app/helpers/dropdowns_helper.rb' do
              element :dropdown_list_content
            end
          end

          def assign_milestone(milestone)
            wait_milestone_block_finish_loading do
              click_element(:edit_link)
              click_on(milestone.title)
            end

            wait_until(reload: false) do
              has_element?(:milestone_block, text: milestone.title, wait: 0)
            end

            refresh
          end

          def click_milestone_link
            click_element(:milestone_link)
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

          def has_reviewer?(username)
            wait_reviewers_block_finish_loading do
              has_text?(username)
            end
          end

          def has_no_reviewer?(username)
            wait_reviewers_block_finish_loading do
              has_no_text?(username)
            end
          end

          def has_no_reviewers?
            wait_reviewers_block_finish_loading do
              has_text?('None')
            end
          end

          def has_avatar_image_count?(count)
            wait_assignees_block_finish_loading do
              all_elements(:avatar_image, count: count)
            end
          end

          def has_label?(label)
            wait_labels_block_finish_loading do
              has_element?(:selected_label_content, label_name: label)
            end
          end

          def has_no_label?(label)
            wait_labels_block_finish_loading do
              has_no_element?(:selected_label_content, label_name: label)
            end
          end

          def has_milestone?(milestone_title)
            wait_milestone_block_finish_loading do
              has_element?(:milestone_link, text: milestone_title)
            end
          end

          def more_assignees_link
            find_element(:more_assignees_link)
          end

          def select_labels(labels)
            within_element(:labels_block) do
              click_element(:edit_link)

              labels.each do |label|
                within_element(:labels_dropdown_content) do
                  fill_element(:dropdown_input_field, label)
                  click_button(text: label)
                end
              end
            end

            click_element(:title_content) # to blur dropdown
          end

          def toggle_more_assignees_link
            click_element(:more_assignees_link)
          end

          def toggle_reviewers_edit
            click_element(:reviewers_edit_button)
          end

          def suggested_reviewer_usernames
            within_element(:reviewers_block_container) do
              wait_for_requests

              click_element(:reviewers_edit_button)
              wait_for_requests

              list = find_element(:dropdown_list_content)
              suggested_reviewers = list.find_all('li[data-user-suggested="true"')
              raise ElementNotFound, 'No suggested reviewers found' if suggested_reviewers.nil?

              suggested_reviewers.map do |reviewer|
                info = reviewer.text.split('@')
                {
                  name: info[0].chomp,
                  username: info[1].chomp
                }
              end.compact
            end
          end

          def unassign_reviewers
            within_element(:reviewers_block_container) do
              wait_for_requests

              click_element(:reviewers_edit_button)
              wait_for_requests
            end

            select_reviewer('Unassigned')
          end

          def select_reviewer(username)
            within_element(:reviewers_block_container) do
              within_element(:dropdown_list_content) do
                click_on username
              end

              click_element(:reviewers_edit_button)
              wait_for_requests
            end
          end

          private

          def wait_assignees_block_finish_loading
            within_element(:assignee_block_container) do
              wait_until(reload: false, max_duration: 10, sleep_interval: 1) do
                finished_loading_block?
                yield
              end
            end
          end

          def wait_reviewers_block_finish_loading
            within_element(:reviewers_block_container) do
              wait_until(reload: false, max_duration: 10, sleep_interval: 1) do
                finished_loading_block?
                yield
              end
            end
          end

          def wait_labels_block_finish_loading
            within_element(:labels_block) do
              wait_until(reload: false, max_duration: 10, sleep_interval: 1) do
                finished_loading_block?
                yield
              end
            end
          end

          def wait_milestone_block_finish_loading
            within_element(:milestone_block) do
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

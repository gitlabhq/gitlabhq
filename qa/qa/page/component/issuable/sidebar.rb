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

            base.view 'app/helpers/dropdowns_helper.rb' do
              element :dropdown_input_field
            end

            base.view 'app/views/shared/issuable/_sidebar.html.haml' do
              element :assignee_block
              element :dropdown_menu_labels
              element :edit_link_labels
              element :labels_block
              element :milestone_block
              element :milestone_link
            end
          end

          def click_milestone_link
            click_element(:milestone_link)
          end

          def has_assignee?(username)
            page.within(element_selector_css(:assignee_block)) do
              has_text?(username)
            end
          end

          def has_avatar_image_count?(count)
            wait_assignees_block_finish_loading do
              all_elements(:avatar_image, count: count)
            end
          end

          def has_label?(label)
            within_element(:labels_block) do
              !!has_element?(:label, label_name: label)
            end
          end

          def has_milestone?(milestone_title)
            within_element(:milestone_block) do
              has_element?(:milestone_link, title: milestone_title)
            end
          end

          def more_assignees_link
            find_element(:more_assignees_link)
          end

          def select_labels_and_refresh(labels)
            Support::Retrier.retry_until do
              click_element(:edit_link_labels)
              has_element?(:dropdown_menu_labels, text: labels.first)
            end

            labels.each do |label|
              within_element(:dropdown_menu_labels, text: label) do
                send_keys_to_element(:dropdown_input_field, [label, :enter])
              end
            end

            click_element(:edit_link_labels)

            labels.each do |label|
              has_element?(:labels_block, text: label, wait: 0)
            end

            refresh
          end

          def text_of_labels_block
            find_element(:labels_block)
          end

          def toggle_more_assignees_link
            click_element(:more_assignees_link)
          end

          private

          def wait_assignees_block_finish_loading
            within_element(:assignee_block) do
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

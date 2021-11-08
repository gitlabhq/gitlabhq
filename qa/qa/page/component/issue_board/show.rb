# frozen_string_literal: true

module QA
  module Page
    module Component
      module IssueBoard
        class Show < QA::Page::Base
          view 'app/assets/javascripts/boards/components/board_card.vue' do
            element :board_card
          end

          view 'app/assets/javascripts/boards/components/board_form.vue' do
            element :board_name_field
            element :save_changes_button
          end

          view 'app/assets/javascripts/boards/components/board_list.vue' do
            element :board_list_cards_area
          end

          view 'app/assets/javascripts/boards/components/boards_selector.vue' do
            element :boards_dropdown
            element :boards_dropdown_content
            element :create_new_board_button
          end

          view 'app/assets/javascripts/vue_shared/components/sidebar/labels_select_vue/dropdown_contents.vue' do
            element :labels_dropdown_content
          end

          view 'app/assets/javascripts/vue_shared/components/sidebar/labels_select_vue/dropdown_title.vue' do
            element :labels_edit_button
          end

          view 'app/assets/javascripts/boards/components/board_content.vue' do
            element :boards_list
          end

          view 'app/assets/javascripts/boards/components/toggle_focus.vue' do
            element :focus_mode_button
          end

          view 'app/assets/javascripts/boards/components/config_toggle.vue' do
            element :boards_config_button
          end

          # The `focused_board` method does not use `find_element` with an element defined
          # with the attribute `data-qa-selector` since such element is not unique when the
          # `is-focused` class is not set, and it was not possible to find a better solution.
          def focused_board
            find('.issue-boards-content.js-focus-mode-board.is-focused')
          end

          def boards_dropdown
            find_element(:boards_dropdown)
          end

          def boards_dropdown_content
            find_element(:boards_dropdown_content)
          end

          def boards_list_cards_area_with_index(index)
            wait_boards_list_finish_loading do
              within_element_by_index(:board_list, index) do
                find_element(:board_list_cards_area)
              end
            end
          end

          def boards_list_header_with_index(index)
            wait_boards_list_finish_loading do
              within_element_by_index(:board_list, index) do
                find_element(:board_list_header)
              end
            end
          end

          def card_of_list_with_index(index)
            wait_boards_list_finish_loading do
              within_element_by_index(:board_list, index) do
                find_element(:board_card)
              end
            end
          end

          def click_boards_config_button
            click_element(:boards_config_button)
          end

          def click_boards_dropdown_button
            # The dropdown button comes from the `GlDropdown` component of `@gitlab/ui`,
            # so it wasn't possible to add a `data-qa-selector` to it.
            find_element(:boards_dropdown).find('button').click
          end

          def click_focus_mode_button
            click_element(:focus_mode_button)
          end

          def configure_by_label(label)
            click_boards_config_button
            click_element(:labels_edit_button)
            find_element(:labels_dropdown_content).find('li', text: label).click
            # Clicking the edit button again closes the dropdown and allows the save button to be clicked
            click_element(:labels_edit_button)
            click_element(:save_changes_button)
            wait_boards_list_finish_loading
          end

          def create_new_board(board_name)
            click_boards_dropdown_button
            click_element(:create_new_board_button)
            set_name(board_name)
          end

          def has_modal_board_name_field?
            has_element?(:board_name_field, wait: 1)
          end

          def set_name(name)
            find_element(:board_name_field).set(name)
            click_element(:save_changes_button)
          end

          private

          def wait_boards_list_finish_loading
            within_element(:boards_list) do
              wait_until(reload: false, max_duration: 5, sleep_interval: 1) do
                finished_loading? && (block_given? ? yield : true)
              end
            end
          end
        end
      end
    end
  end
end

QA::Page::Component::IssueBoard::Show.prepend_mod_with('Page::Component::IssueBoard::Show', namespace: QA)

# frozen_string_literal: true

module QA
  module Page
    module Component
      module IssueBoard
        class Show < QA::Page::Base
          view 'app/assets/javascripts/boards/components/board_card.vue' do
            element 'board-card'
          end

          view 'app/assets/javascripts/boards/components/board_column.vue' do
            element 'board-list'
          end

          view 'app/assets/javascripts/boards/components/board_form.vue' do
            element 'board-name-field'
            element 'save-changes-button'
          end

          view 'app/assets/javascripts/boards/components/board_list.vue' do
            element 'board-list-cards-area'
          end

          view 'app/assets/javascripts/boards/components/board_list_header.vue' do
            element 'board-list-header'
          end

          view 'app/assets/javascripts/boards/components/boards_selector.vue' do
            element 'boards-dropdown'
            element 'create-new-board-button'
          end

          view 'app/assets/javascripts/boards/components/board_content.vue' do
            element 'boards-list'
          end

          view 'app/assets/javascripts/boards/components/toggle_focus.vue' do
            element 'focus-mode-button'
          end

          view 'app/assets/javascripts/boards/components/config_toggle.vue' do
            element 'boards-config-button'
          end

          # The `focused_board` method does not use `find_element` with an element defined
          # with the attribute `data-testid` since such element is not unique when the
          # `is-focused` class is not set, and it was not possible to find a better solution.
          def focused_board
            find('.issue-boards-content.js-focus-mode-board.is-focused')
          end

          def boards_dropdown
            find_element('boards-dropdown')
          end

          def boards_list_cards_area_with_index(index)
            wait_boards_list_finish_loading do
              within_element_by_index('board-list', index) do
                find_element('board-list-cards-area')
              end
            end
          end

          def boards_list_header_with_index(index)
            wait_boards_list_finish_loading do
              within_element_by_index('board-list', index) do
                find_element('board-list-header')
              end
            end
          end

          def card_of_list_with_index(index)
            wait_boards_list_finish_loading do
              within_element_by_index('board-list', index) do
                find_element('board-card')
              end
            end
          end

          def click_boards_config_button
            click_element('boards-config-button')
            wait_for_requests
          end

          def click_boards_dropdown_button
            # The dropdown button comes from the `GlDropdown` component of `@gitlab/ui`,
            # so it wasn't possible to add a `data-testid` to it.
            find_element('boards-dropdown').find('button').click
          end

          def click_focus_mode_button
            click_element('focus-mode-button')
          end

          def create_new_board(board_name)
            click_boards_dropdown_button
            click_element('create-new-board-button')
            set_name(board_name)
          end

          def has_modal_board_name_field?
            has_element?('board-name-field', wait: 1)
          end

          def set_name(name)
            find_element('board-name-field').set(name)
            click_element('save-changes-button')
          end

          private

          def wait_boards_list_finish_loading
            within_element('boards-list') do
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

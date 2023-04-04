# frozen_string_literal: true

module QA
  module Page
    module File
      class Show < Page::Base
        include Shared::CommitMessage
        include Layout::Flash
        include Page::Component::BlobContent

        view 'app/assets/javascripts/repository/components/blob_button_group.vue' do
          element :lock_button
        end

        view 'app/assets/javascripts/vue_shared/components/web_ide_link.vue' do
          element :edit_button
        end

        view 'app/assets/javascripts/vue_shared/components/actions_button.vue' do
          element :action_dropdown
          element :edit_menu_item, ':data-qa-selector="`${action.key}_menu_item`"' # rubocop:disable QA/ElementWithPattern
        end

        def click_edit
          within_element(:action_dropdown) do
            click_button(class: 'dropdown-toggle-split')
            click_element(:edit_menu_item)
            click_element(:edit_button)
          end
        end

        def click_delete
          click_on 'Delete'
        end

        def click_delete_file
          click_on 'Delete file'
        end
      end
    end
  end
end

QA::Page::File::Show.prepend_mod_with('Page::File::Show', namespace: QA)

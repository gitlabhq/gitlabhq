# frozen_string_literal: true

module QA
  module Page
    module File
      class Show < Page::Base
        include Shared::CommitMessage
        include Layout::Flash
        include Page::Component::BlobContent
        include Shared::Editor

        view 'app/assets/javascripts/repository/components/blob_button_group.vue' do
          element 'lock-button'
        end

        view 'app/assets/javascripts/vue_shared/components/web_ide_link.vue' do
          element 'action-dropdown'
          element 'edit-menu-item', ':data-testid="`${action.key}-menu-item`"' # rubocop:disable QA/ElementWithPattern
          element 'webide-menu-item', ':data-testid="`${action.key}-menu-item`"' # rubocop:disable QA/ElementWithPattern
        end

        def click_edit
          click_element('action-dropdown')
          click_element('edit-menu-item')
        end

        def click_delete
          click_on 'Delete'
        end

        def highlight_text
          find_element('content').double_click
        end

        def explain_code
          click_element('question-icon')
        end
      end
    end
  end
end

QA::Page::File::Show.prepend_mod_with('Page::File::Show', namespace: QA)

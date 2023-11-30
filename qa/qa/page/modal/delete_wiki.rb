# frozen_string_literal: true

module QA
  module Page
    module Modal
      class DeleteWiki < Base
        view 'app/assets/javascripts/pages/shared/wikis/components/delete_wiki_modal.vue' do
          element 'confirm-deletion-button', required: true
        end

        def confirm_deletion
          click_element 'confirm-deletion-button'
        end
      end
    end
  end
end

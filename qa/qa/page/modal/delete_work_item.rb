# frozen_string_literal: true

module QA
  module Page
    module Modal
      class DeleteWorkItem < Base
        view 'app/assets/javascripts/work_items/components/work_item_actions.vue' do
          element 'work-item-confirm-delete'
        end

        def confirm_delete_work_item
          within_element('work-item-confirm-delete') do
            click_button('Delete issue')
          end
        end
      end
    end
  end
end

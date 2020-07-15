# frozen_string_literal: true

module QA
  module Page
    module Component
      module WebIDE
        module Modal
          class CreateNewFile < Page::Base
            view 'app/assets/javascripts/ide/components/new_dropdown/modal.vue' do
              element :file_name_field, required: true
              element :new_file_modal, required: true
              element :template_list
            end
          end
        end
      end
    end
  end
end

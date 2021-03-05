# frozen_string_literal: true

module QA
  module Page
    module Project
      module Registry
        class Show < QA::Page::Base
          view 'app/assets/javascripts/registry/explorer/components/list_page/image_list_row.vue' do
            element :registry_image_content
          end

          view 'app/assets/javascripts/registry/explorer/components/details_page/tags_list_row.vue' do
            element :tag_delete_button
          end

          def has_registry_repository?(name)
            find_element(:registry_image_content, text: name)
          end

          def click_on_image(name)
            click_element(:registry_image_content, text: name)
          end

          def has_tag?(tag_name)
            has_button?(tag_name)
          end

          def has_no_tag?(tag_name)
            has_no_button?(tag_name)
          end

          def click_delete
            click_element(:tag_delete_button)
            find_button('Confirm').click
          end
        end
      end
    end
  end
end

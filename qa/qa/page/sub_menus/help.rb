# frozen_string_literal: true

module QA
  module Page
    module SubMenus
      module Help
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.class_eval do
            include QA::Page::SubMenus::Common

            view 'app/assets/javascripts/super_sidebar/components/help_center.vue' do
              element 'sidebar-help-button'
              element 'duo-chat-menu-item'
            end
          end
        end

        def open_duo_chat
          open_help
          click_element('duo-chat-menu-item')
        end

        private

        def open_help
          click_element('sidebar-help-button')
        end
      end
    end
  end
end

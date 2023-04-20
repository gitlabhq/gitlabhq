# frozen_string_literal: true

module QA
  module Page
    module SubMenus
      module SuperSidebar
        module ContextSwitcher
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              view 'app/assets/javascripts/super_sidebar/components/super_sidebar.vue' do
                element :context_switcher
                element :context_section
              end
            end
          end

          def go_to_your_work
            go_to_context("Your work")
          end

          def go_to_explore
            go_to_context("Explore")
          end

          def go_to_admin_area
            go_to_context("Admin")
          end

          private

          def go_to_context(sub_menu)
            click_element(:context_switcher) unless has_element?(:context_section, wait: 0)

            within_element(:context_section) do
              click_element(:nav_item_link, submenu_item: sub_menu)
            end
          end
        end
      end
    end
  end
end

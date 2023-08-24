# frozen_string_literal: true

module QA
  module Page
    module SubMenus
      module SuperSidebar
        module ContextSwitcher
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              view 'app/assets/javascripts/super_sidebar/components/context_switcher_toggle.vue' do
                element 'context-switcher'
              end

              view 'app/assets/javascripts/super_sidebar/components/context_switcher.vue' do
                element 'context-navigation'
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
            go_to_context("Admin Area")
            return unless has_text?('Enter admin mode', wait: 1.0)

            Admin::NewSession.perform do |new_session|
              new_session.set_password(Runtime::User.admin_password)
              new_session.click_enter_admin_mode
            end
          end

          def has_admin_area_link?(wait: Capybara.default_max_wait_time)
            open_context_switcher

            has_element?(:nav_item_link, submenu_item: "Admin Area", wait: wait)
          end

          private

          def go_to_context(sub_menu)
            open_context_switcher
            click_element(:nav_item_link, submenu_item: sub_menu)
          end

          def open_context_switcher
            click_element('context-switcher') unless has_element?('context-navigation', wait: 0)
          end
        end
      end
    end
  end
end

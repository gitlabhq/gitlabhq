# frozen_string_literal: true

module QA
  module Mobile
    module Page
      module Main
        module Menu
          extend QA::Page::PageConcern

          def self.prepended(base)
            super

            base.class_eval do
              view 'app/views/layouts/header/_default.html.haml' do
                element :mobile_navbar_button, required: true
              end

              view 'app/assets/javascripts/nav/components/responsive_home.vue' do
                element :mobile_new_dropdown
              end
            end
          end

          def open_mobile_menu
            if has_no_element?(:user_avatar_content)
              Support::Retrier.retry_until do
                click_element(:mobile_navbar_button)
                has_element?(:user_avatar_content)
              end
            end
          end

          def open_mobile_new_dropdown
            open_mobile_menu

            Support::Retrier.retry_until do
              find('[data-qa-selector="mobile_new_dropdown"] > button').click
              has_css?('.dropdown-menu-right.show')
            end
          end

          def has_personal_area?(wait: Capybara.default_max_wait_time)
            open_mobile_menu
            super
          end

          def has_no_personal_area?(wait: Capybara.default_max_wait_time)
            open_mobile_menu
            super
          end

          def within_user_menu
            open_mobile_menu
            super
          end
        end
      end
    end
  end
end

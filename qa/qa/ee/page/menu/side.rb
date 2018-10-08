# frozen_string_literal: true

module QA
  module EE
    module Page
      module Menu
        class Side < ::QA::Page::Base
          view 'ee/app/views/groups/ee/_settings_nav.html.haml' do
            element :group_saml_sso_link
          end

          view 'app/views/layouts/nav/sidebar/_group.html.haml' do
            element :group_sidebar
            element :group_sidebar_submenu
            element :group_settings_item
          end

          def go_to_saml_sso_group_settings
            hover_settings do
              within_submenu do
                click_element :group_saml_sso_link
              end
            end
          end

          private

          def hover_settings
            within_sidebar do
              find_element(:group_settings_item).hover
              yield
            end
          end

          def within_sidebar
            within_element(:group_sidebar) do
              yield
            end
          end

          def within_submenu
            within_element(:group_sidebar_submenu) do
              yield
            end
          end
        end
      end
    end
  end
end

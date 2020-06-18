# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Settings
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include QA::Page::Project::SubMenus::Common

              view 'app/views/layouts/nav/sidebar/_project.html.haml' do
                element :settings_item
                element :general_settings_link
                element :integrations_settings_link
                element :operations_settings_link
              end
            end
          end

          def go_to_ci_cd_settings
            hover_settings do
              within_submenu do
                click_link('CI / CD')
              end
            end
          end

          def go_to_repository_settings
            hover_settings do
              within_submenu do
                click_link('Repository')
              end
            end
          end

          def go_to_general_settings
            hover_settings do
              within_submenu do
                click_element :general_settings_link
              end
            end
          end

          def click_settings
            within_sidebar do
              click_on 'Settings'
            end
          end

          def go_to_integrations_settings
            hover_settings do
              within_submenu do
                click_element :integrations_settings_link
              end
            end
          end

          def go_to_operations_settings
            hover_settings do
              within_submenu do
                click_element :operations_settings_link
              end
            end
          end

          private

          def hover_settings
            within_sidebar do
              scroll_to_element(:settings_item)
              find_element(:settings_item).hover

              yield
            end
          end
        end
      end
    end
  end
end

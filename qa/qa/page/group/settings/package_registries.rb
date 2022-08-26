# frozen_string_literal: true
module QA
  module Page
    module Group
      module Settings
        class PackageRegistries < QA::Page::Base
          include ::QA::Page::Settings::Common

          view 'app/assets/javascripts/packages_and_registries/settings/group/components/packages_settings.vue' do
            element :package_registry_settings_content
            element :allow_duplicates_toggle
          end

          view 'app/assets/javascripts/packages_and_registries/settings/group/components/dependency_proxy_settings.vue' do
            element :dependency_proxy_settings_content
            element :dependency_proxy_setting_toggle
          end

          def set_allow_duplicates_disabled
            within_element :package_registry_settings_content do
              click_on_allow_duplicates_button if duplicates_enabled?
            end
          end

          def set_allow_duplicates_enabled
            within_element :package_registry_settings_content do
              click_on_allow_duplicates_button unless duplicates_enabled?
            end
          end

          def click_on_allow_duplicates_button
            with_allow_duplicates_button do |button|
              button.click
            end
          end

          def duplicates_enabled?
            with_allow_duplicates_button do |button|
              button[:class].include?('is-checked')
            end
          end

          def with_allow_duplicates_button
            within_element :allow_duplicates_toggle do
              toggle = find('button.gl-toggle:not(.is-disabled)')
              yield(toggle)
            end
          end

          def has_dependency_proxy_enabled?
            within_element :dependency_proxy_settings_content do
              within_element :dependency_proxy_setting_toggle do
                toggle = find('button.gl-toggle')
                toggle[:class].include?('is-checked')
              end
            end
          end
        end
      end
    end
  end
end

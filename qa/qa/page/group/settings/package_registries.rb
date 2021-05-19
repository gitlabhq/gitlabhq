# frozen_string_literal: true

module QA
  module Page
    module Group
      module Settings
        class PackageRegistries < QA::Page::Base
          include ::QA::Page::Settings::Common

          view 'app/assets/javascripts/packages_and_registries/settings/group/components/group_settings_app.vue' do
            element :package_registry_settings_content
          end

          view 'app/assets/javascripts/packages_and_registries/settings/group/components/group_settings_app.vue' do
            element :allow_duplicates_toggle
            element :allow_duplicates_label
          end

          def set_allow_duplicates_disabled
            expand_content :package_registry_settings_content do
              click_element(:allow_duplicates_toggle) if duplicates_enabled?
            end
          end

          def set_allow_duplicates_enabled
            expand_content :package_registry_settings_content do
              click_element(:allow_duplicates_toggle) if duplicates_disabled?
            end
          end

          def duplicates_enabled?
            has_element?(:allow_duplicates_label, text: 'Allow duplicates')
          end

          def duplicates_disabled?
            has_element?(:allow_duplicates_label, text: 'Do not allow duplicates')
          end
        end
      end
    end
  end
end

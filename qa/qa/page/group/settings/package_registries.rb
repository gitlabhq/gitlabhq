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

          view 'app/assets/javascripts/packages_and_registries/settings/group/components/maven_settings.vue' do
            element :allow_duplicates_checkbox
          end

          def set_allow_duplicates_disabled
            expand_content :package_registry_settings_content do
              uncheck_element :allow_duplicates_checkbox
            end
          end

          def has_allow_duplicates_enabled?
            expand_content :package_registry_settings_content
            !find_element(:allow_duplicates_checkbox).checked?
          end
        end
      end
    end
  end
end

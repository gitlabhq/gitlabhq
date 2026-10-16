# frozen_string_literal: true

module QA
  module Page
    module Group
      module Settings
        class PackageRegistries < QA::Page::Base
          include ::QA::Page::Settings::Common

          view 'app/assets/javascripts/packages_and_registries/settings/group/components/dependency_proxy_settings.vue' do
            element 'dependency-proxy-settings-content'
            element 'dependency-proxy-setting-toggle'
          end

          def has_dependency_proxy_enabled?
            within_element 'dependency-proxy-settings-content' do
              within_element 'dependency-proxy-setting-toggle' do
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

# frozen_string_literal: true

module QA
  module Page
    module Project
      module Packages
        class Show < QA::Page::Base
          view 'app/assets/javascripts/packages_and_registries/package_registry/pages/details.vue' do
            element 'delete-package'
            element 'delete-modal-button'
            element 'package-information-content'
          end

          def has_package_info?(name, version)
            has_element?('package-information-content', text: /#{name}.*#{version}/)
          end

          def click_delete
            click_element('delete-package')
            wait_for_animated_element('delete-modal-button')
            click_element('delete-modal-button')
          end
        end
      end
    end
  end
end

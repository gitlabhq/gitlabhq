# frozen_string_literal: true

module QA
  module Page
    module Explore
      class CiCdCatalog
        class Show < Page::Base
          view 'app/assets/javascripts/ci/catalog/components/details/ci_resource_header.vue' do
            element 'latest-version-badge'
          end

          view 'app/assets/javascripts/ci/catalog/components/details/ci_resource_components.vue' do
            element 'component-name'
            element 'input-name'
            element 'input-required'
            element 'input-type'
            element 'input-description'
            element 'input-default'
          end

          def click_latest_version_badge
            click_element('latest-version-badge')
          end

          def has_input?(name:, required:, type:, description:, default:)
            has_element?('input-name', text: name) &&
              has_element?('input-required', text: required) &&
              has_element?('input-type', text: type) &&
              has_element?('input-description', text: description) &&
              has_element?('input-default', text: default)
          end

          def has_version_badge?(version)
            has_element?('latest-version-badge', text: version)
          end

          def has_component_name?(name)
            has_element?('component-name', text: name)
          end
        end
      end
    end
  end
end

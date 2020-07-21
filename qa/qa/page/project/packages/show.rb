# frozen_string_literal: true

module QA
  module Page
    module Project
      module Packages
        class Show < QA::Page::Base
          view 'app/assets/javascripts/packages/details/components/app.vue' do
            element :delete_button
            element :delete_modal_button
            element :package_information_content
          end

          def has_package_info?(name, version)
            has_element?(:package_information_content, text: /#{name}.*#{version}/)
          end

          def click_delete
            click_element(:delete_button)
            wait_for_animated_element(:delete_modal_button)
            click_element(:delete_modal_button)
          end
        end
      end
    end
  end
end

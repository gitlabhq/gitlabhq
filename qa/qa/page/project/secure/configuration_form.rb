# frozen_string_literal: true

module QA
  module Page
    module Project
      module Secure
        class ConfigurationForm < QA::Page::Base
          include QA::Page::Component::Select2
          include QA::Page::Settings::Common

          view 'app/assets/javascripts/security_configuration/components/feature_card.vue' do
            element :sast_status, "`${feature.type}_status`" # rubocop:disable QA/ElementWithPattern
            element :sast_enable_button, "`${feature.type}_enable_button`" # rubocop:disable QA/ElementWithPattern
          end

          def click_sast_enable_button
            click_element(:sast_enable_button)
          end

          def has_sast_status?(status_text)
            within_element(:sast_status) do
              has_text?(status_text)
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Secure::ConfigurationForm.prepend_mod_with('Page::Project::Secure::ConfigurationForm', namespace: QA)

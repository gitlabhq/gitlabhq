# frozen_string_literal: true

module QA
  module Page
    module Project
      module Secure
        class ConfigurationForm < QA::Page::Base
          include QA::Page::Settings::Common

          view 'app/assets/javascripts/security_configuration/components/app.vue' do
            element :security_configuration_container
            element :security_configuration_history_link
          end

          view 'app/assets/javascripts/security_configuration/components/feature_card.vue' do
            element :dependency_scanning_status, "`${feature.type}_status`" # rubocop:disable QA/ElementWithPattern
            element :sast_status, "`${feature.type}_status`" # rubocop:disable QA/ElementWithPattern
            element :sast_enable_button, "`${feature.type}_enable_button`" # rubocop:disable QA/ElementWithPattern
            element :dependency_scanning_mr_button, "`${feature.type}_mr_button`" # rubocop:disable QA/ElementWithPattern
            element :license_scanning_status, "`${feature.type}_status`" # rubocop:disable QA/ElementWithPattern
          end

          view 'app/assets/javascripts/security_configuration/components/auto_dev_ops_alert.vue' do
            element :autodevops_container
          end

          def has_security_configuration_history_link?
            has_element?(:security_configuration_history_link)
          end

          def has_no_security_configuration_history_link?
            has_no_element?(:security_configuration_history_link)
          end

          def click_security_configuration_history_link
            click_element(:security_configuration_history_link)
          end

          def click_sast_enable_button
            click_element(:sast_enable_button)
          end

          def click_dependency_scanning_mr_button
            click_element(:dependency_scanning_mr_button)
          end

          def has_sast_status?(status_text)
            within_element(:sast_status) do
              has_text?(status_text)
            end
          end

          def has_no_sast_status?(status_text)
            within_element(:sast_status) do
              has_no_text?(status_text)
            end
          end

          def has_dependency_scanning_status?(status_text)
            within_element(:dependency_scanning_status) do
              has_text?(status_text)
            end
          end

          def has_no_dependency_scanning_status?(status_text)
            within_element(:dependency_scanning_status) do
              has_no_text?(status_text)
            end
          end

          def has_license_compliance_status?(status_text)
            within_element(:license_scanning_status) do
              has_text?(status_text)
            end
          end

          def has_no_license_compliance_status?(status_text)
            within_element(:license_scanning_status) do
              has_no_text?(status_text)
            end
          end

          def has_auto_devops_container?
            has_element?(:autodevops_container)
          end

          def has_no_auto_devops_container?
            has_no_element?(:autodevops_container)
          end

          def has_auto_devops_container_description?
            within_element(:autodevops_container) do
              has_text?('Quickly enable all continuous testing and compliance tools by enabling Auto DevOps')
            end
          end

          def go_to_compliance_tab
            go_to_tab('Compliance')
          end

          private

          def go_to_tab(name)
            within_element(:security_configuration_container) do
              find('.nav-item', text: name).click
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Secure::ConfigurationForm.prepend_mod_with('Page::Project::Secure::ConfigurationForm', namespace: QA)

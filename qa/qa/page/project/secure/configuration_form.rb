# frozen_string_literal: true

module QA
  module Page
    module Project
      module Secure
        class ConfigurationForm < QA::Page::Base
          include QA::Page::Settings::Common

          view 'app/assets/javascripts/security_configuration/components/app.vue' do
            element 'security-configuration-container'
            element 'security-view-history-link'
          end

          view 'app/assets/javascripts/security_configuration/components/feature_card.vue' do
            element 'feature-status'
            element 'sast-enable-button', "`${hyphenatedFeature}-enable-button`" # rubocop:disable QA/ElementWithPattern
            element 'dependency-scanning-mr-button', "`${hyphenatedFeature}-mr-button`" # rubocop:disable QA/ElementWithPattern
          end

          view 'app/assets/javascripts/security_configuration/components/auto_dev_ops_alert.vue' do
            element 'autodevops-container'
          end

          def has_security_configuration_history_link?
            has_element?('security-view-history-link')
          end

          def has_no_security_configuration_history_link?
            has_no_element?('security-view-history-link')
          end

          def click_security_configuration_history_link
            click_element('security-view-history-link')
          end

          def click_sast_enable_button
            click_element('sast-enable-button')
          end

          def click_dependency_scanning_mr_button
            click_element('dependency-scanning-mr-button')
          end

          def has_true_sast_status?
            has_element?('feature-status', feature: 'sast_true_status')
          end

          def has_false_sast_status?
            has_element?('feature-status', feature: 'sast_false_status')
          end

          def has_true_dependency_scanning_status?
            has_element?('feature-status', feature: 'dependency_scanning_true_status')
          end

          def has_false_dependency_scanning_status?
            has_element?('feature-status', feature: 'dependency_scanning_false_status')
          end

          def has_auto_devops_container?
            has_element?('autodevops-container')
          end

          def has_no_auto_devops_container?
            has_no_element?('autodevops-container')
          end

          def has_auto_devops_container_description?
            within_element('autodevops-container') do
              has_text?('Quickly enable all continuous testing and compliance tools by enabling Auto DevOps')
            end
          end

          def go_to_compliance_tab
            go_to_tab('Compliance')
          end

          private

          def go_to_tab(name)
            within_element('security-configuration-container') do
              find('.nav-item', text: name).click
            end
          end
        end
      end
    end
  end
end

QA::Page::Project::Secure::ConfigurationForm.prepend_mod_with('Page::Project::Secure::ConfigurationForm', namespace: QA)

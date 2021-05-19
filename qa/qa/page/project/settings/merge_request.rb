# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class MergeRequest < QA::Page::Base
          include QA::Page::Settings::Common

          view 'app/views/projects/edit.html.haml' do
            element :save_merge_request_changes_button
          end

          view 'app/views/projects/_merge_request_merge_method_settings.html.haml' do
            element :merge_ff_radio
          end

          view 'app/views/projects/_merge_request_merge_checks_settings.html.haml' do
            element :allow_merge_if_all_discussions_are_resolved_checkbox
          end

          def click_save_changes
            click_element(:save_merge_request_changes_button)
          end

          def enable_ff_only
            choose_element(:merge_ff_radio)
            click_save_changes
          end

          def enable_merge_if_all_disscussions_are_resolved
            check_element(:allow_merge_if_all_discussions_are_resolved_checkbox)
            click_save_changes
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::MergeRequest.prepend_mod_with("Page::Project::Settings::MergeRequest", namespace: QA)

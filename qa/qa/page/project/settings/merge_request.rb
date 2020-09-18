# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class MergeRequest < QA::Page::Base
          include QA::Page::Settings::Common

          view 'app/views/projects/edit.html.haml' do
            element :save_merge_request_changes
          end

          view 'app/views/projects/_merge_request_merge_method_settings.html.haml' do
            element :radio_button_merge_ff
          end

          view 'app/views/projects/_merge_request_merge_checks_settings.html.haml' do
            element :allow_merge_if_all_discussions_are_resolved_checkbox
          end

          def click_save_changes
            click_element :save_merge_request_changes
          end

          def enable_ff_only
            click_element :radio_button_merge_ff
            click_save_changes
          end

          def enable_merge_if_all_disscussions_are_resolved
            click_element :allow_merge_if_all_discussions_are_resolved_checkbox
            click_save_changes
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::MergeRequest.prepend_if_ee("QA::EE::Page::Project::Settings::MergeRequest")

# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class MergeRequest < QA::Page::Base
          include QA::Page::Settings::Common

          view 'app/views/projects/settings/merge_requests/show.html.haml' do
            element 'save-merge-request-changes-button'
          end

          view 'app/views/projects/settings/merge_requests/_merge_request_merge_method_settings.html.haml' do
            element 'merge-ff-radio'
          end

          def click_save_changes
            click_element('save-merge-request-changes-button')
          end

          def enable_ff_only
            choose_element('merge-ff-radio', true)
            click_save_changes
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::MergeRequest.prepend_mod_with("Page::Project::Settings::MergeRequest", namespace: QA)

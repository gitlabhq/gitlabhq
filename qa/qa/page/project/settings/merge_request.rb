module QA
  module Page
    module Project
      module Settings
        class MergeRequest < QA::Page::Base
          include Common

          view 'app/views/projects/edit.html.haml' do
            element :merge_request_settings
            element :save_merge_request_changes
          end

          view 'app/views/projects/_merge_request_merge_method_settings.html.haml' do
            element :radio_button_merge_ff
          end

          def enable_ff_only
            expand_section(:merge_request_settings) do
              click_element :radio_button_merge_ff
              click_element :save_merge_request_changes
            end
          end
        end
      end
    end
  end
end

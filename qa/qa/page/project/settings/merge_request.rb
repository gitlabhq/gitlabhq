module QA
  module Page
    module Project
      module Settings
        class MergeRequest < QA::Page::Base
          include Common

          view 'app/views/projects/_merge_request_fast_forward_settings.html.haml' do
            element :radio_button_merge_ff
          end

          view 'app/views/projects/edit.html.haml' do
            element :merge_request_settings, 'Merge request settings'
            element :save_merge_request_changes
          end

          def enable_ff_only
            expand_section('Merge request settings') do
              click_element :radio_button_merge_ff
              click_element :save_merge_request_changes
            end
          end
        end
      end
    end
  end
end

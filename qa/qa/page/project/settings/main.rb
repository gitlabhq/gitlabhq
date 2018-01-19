module QA
  module Page
    module Project
      module Settings
        class Main < Page::Base
          include Common

          view 'app/views/projects/edit.html.haml' do
            element :advanced_settings_section, '%section.settings.advanced-settings'
          end

          def expand_advanced_settings(&block)
            expand_section('section.advanced-settings') do
              Advanced.perform(&block)
            end
          end
        end
      end
    end
  end
end

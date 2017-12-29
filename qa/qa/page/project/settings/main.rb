module QA
  module Page
    module Project
      module Settings
        class Main < Page::Base
          def expand_advanced_settings
            within('section.advanced-settings') do
              find_button('Expand').click
            end
          end

          def rename_to(path)
            fill_in :project_name, with: path
            fill_in :project_path, with: path
            click_on 'Rename project'
          end
        end
      end
    end
  end
end

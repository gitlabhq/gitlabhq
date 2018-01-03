module QA
  module Page
    module Project
      module Settings
        class Main < Page::Base
          include Common

          def expand_advanced_settings
            expand_section('section.advanced-settings')
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

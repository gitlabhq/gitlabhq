module QA
  module Page
    module Project
      module Settings
        class Advanced < Page::Base
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

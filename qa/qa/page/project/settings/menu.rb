module QA
  module Page
    module Project
      module Settings
        class Menu < Page::Base
          def go_to_repository
            link = find_link 'Repository'
            link.click
          end
        end
      end
    end
  end
end

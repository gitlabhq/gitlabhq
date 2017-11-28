require 'pry'

module QA
  module Page
    module Project
      module Settings
        class Menu < Page::Base
          def go_to_repository
            click_link 'Repository', href: /settings/
          end
        end
      end
    end
  end
end

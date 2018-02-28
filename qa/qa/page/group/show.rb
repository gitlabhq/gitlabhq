module QA
  module Page
    module Group
      class Show < Page::Base
        def go_to_new_project
          click_link 'New Project'
        end
      end
    end
  end
end

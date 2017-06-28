module QA
  module Page
    module Main
      class Projects < Page::Base
        def go_to_new_project
          ##
          # There are 'New Project' and 'New project' buttons on the projects
          # page, so we can't use `click_on`.
          #
          button = find('a', text: /^new project$/i)
          button.click
        end
      end
    end
  end
end

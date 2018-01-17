module QA
  module Page
    module Dashboard
      class Projects < Page::Base
        view 'app/views/dashboard/projects/index.html.haml'

        def go_to_project(name)
          find_link(text: name).click
        end
      end
    end
  end
end

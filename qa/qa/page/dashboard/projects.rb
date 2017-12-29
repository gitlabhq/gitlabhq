module QA
  module Page
    module Dashboard
      class Projects < Page::Base
        view 'app/views/dashboard/projects/index.html.haml'

        def go_to_project(name)
          page.within('form#project-filter-form') do
            fill_in :name, with: name
            page.find_field('name').native.send_key(:enter)
          end

          find_link(text: name).click
        end
      end
    end
  end
end

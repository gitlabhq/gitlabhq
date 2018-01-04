module QA
  module Page
    module Dashboard
      class Projects < Page::Base
        view 'app/views/dashboard/projects/index.html.haml'

        def go_to_project(name)
          filter_by_name(name)

          find_link(text: name).click
        end

        def filter_by_name(name)
          page.within('form#project-filter-form') do
            fill_in :name, with: name
            page.find_field('name').native.send_key(:enter)
          end
        end
      end
    end
  end
end

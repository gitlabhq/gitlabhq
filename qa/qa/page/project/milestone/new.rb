module QA
  module Page
    module Project
      module Milestone
        class New < Page::Base
          view 'app/views/projects/milestones/_form.html.haml' do
            element :milestone_create_button
            element :milestone_title
            element :milestone_description
          end

          def set_title(title)
            fill_element :milestone_title, title
          end

          def set_description(description)
            fill_element :milestone_description, description
          end

          def create_new_milestone
            click_element :milestone_create_button
          end
        end
      end
    end
  end
end

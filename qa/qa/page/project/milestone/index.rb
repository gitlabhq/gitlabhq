module QA
  module Page
    module Project
      module Milestone
        class Index < Page::Base
          view 'app/views/projects/milestones/index.html.haml' do
            element :new_project_milestone
          end

          def click_new_milestone
            click_element :new_project_milestone
          end
        end
      end
    end
  end
end

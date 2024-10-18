# frozen_string_literal: true

module QA
  module Page
    module Project
      module Milestone
        class New < Page::Milestone::New
          view 'app/views/projects/milestones/_form.html.haml' do
            element 'create-milestone-button'
            element 'milestone-description-field'
            element 'milestone-title-field'
          end

          def click_create_milestone_button
            click_element('create-milestone-button')
          end

          def set_title(title)
            fill_element('milestone-title-field', title)
          end

          def set_description(description)
            fill_editor_element('milestone-description-field', description)
          end
        end
      end
    end
  end
end

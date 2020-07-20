# frozen_string_literal: true

module QA
  module Page
    module Group
      module Milestone
        class New < Page::Milestone::New
          view 'app/views/groups/milestones/_form.html.haml' do
            element :create_milestone_button
            element :milestone_description_field
            element :milestone_title_field
          end

          def click_create_milestone_button
            click_element(:create_milestone_button)
          end

          def set_description(description)
            fill_element(:milestone_description_field, description)
          end

          def set_title(title)
            fill_element(:milestone_title_field, title)
          end
        end
      end
    end
  end
end

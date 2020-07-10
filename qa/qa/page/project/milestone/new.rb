# frozen_string_literal: true

module QA
  module Page
    module Project
      module Milestone
        class New < Page::Milestone::New
          view 'app/views/projects/milestones/_form.html.haml' do
            element :create_milestone_button
            element :milestone_description_field
            element :milestone_title_field
          end

          view 'app/views/shared/milestones/_form_dates.html.haml' do
            element :due_date_field
            element :start_date_field
          end

          def click_create_milestone_button
            click_element :create_milestone_button
          end

          def set_title(title)
            fill_element :milestone_title_field, title
          end

          def set_description(description)
            fill_element :milestone_description_field, description
          end

          def set_due_date(due_date)
            fill_element :due_date_field, due_date.to_s + "\n"
          end

          def set_start_date(start_date)
            fill_element :start_date_field, start_date.to_s + "\n"
          end
        end
      end
    end
  end
end

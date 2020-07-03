# frozen_string_literal: true

module QA
  module Page
    module Project
      module Milestone
        class Show < ::QA::Page::Base
          include Support::Dates

          view 'app/views/shared/milestones/_description.html.haml' do
            element :milestone_title_content, required: true
            element :milestone_description_content
          end

          view 'app/views/shared/milestones/_sidebar.html.haml' do
            element :due_date_content
            element :start_date_content
          end

          def has_due_date?(due_date)
            formatted_due_date = format_date(due_date)
            has_element?(:due_date_content, text: formatted_due_date)
          end

          def has_start_date?(start_date)
            formatted_start_date = format_date(start_date)
            has_element?(:start_date_content, text: formatted_start_date)
          end
        end
      end
    end
  end
end

QA::Page::Project::Milestone::Show.prepend_if_ee('QA::EE::Page::Project::Milestone::Show')

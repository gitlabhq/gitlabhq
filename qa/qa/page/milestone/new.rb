# frozen_string_literal: true

module QA
  module Page
    module Milestone
      class New < Page::Base
        view 'app/views/shared/milestones/_form_dates.html.haml' do
          element 'due-date-field'
          element 'start-date-field'
        end

        def set_due_date(due_date)
          fill_element('due-date-field', due_date.to_s + "\n")
        end

        def set_start_date(start_date)
          fill_element('start-date-field', start_date.to_s + "\n")
        end
      end
    end
  end
end

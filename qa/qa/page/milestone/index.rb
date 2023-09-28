# frozen_string_literal: true

module QA
  module Page
    module Milestone
      class Index < Page::Base
        view 'app/views/shared/milestones/_milestone.html.haml' do
          element 'milestone-link'
        end

        def click_milestone(milestone)
          click_element('milestone-link', milestone_title: milestone.title)
        end

        def has_milestone?(milestone)
          has_element?('milestone-link', milestone_title: milestone.title)
        end
      end
    end
  end
end

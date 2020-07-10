# frozen_string_literal: true

module QA
  module Page
    module Milestone
      class Index < Page::Base
        view 'app/views/shared/milestones/_milestone.html.haml' do
          element :milestone_link
        end

        def click_milestone(milestone)
          click_element(:milestone_link, milestone_title: milestone.title)
        end

        def has_milestone?(milestone)
          has_element?(:milestone_link, milestone_title: milestone.title)
        end
      end
    end
  end
end

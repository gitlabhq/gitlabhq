# frozen_string_literal: true

module QA
  module Page
    module Project
      module Milestone
        class Index < Page::Milestone::Index
          view 'app/views/projects/milestones/index.html.haml' do
            element 'new-project-milestone-link'
          end

          view 'app/views/shared/milestones/_milestone.html.haml' do
            element 'milestone-link'
          end

          def click_new_milestone_link
            click_element('new-project-milestone-link')
          end

          def has_milestone?(milestone)
            has_element?('milestone-link', milestone_title: milestone.title)
          end

          def click_milestone(milestone)
            click_element('milestone-link', milestone_title: milestone.title)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module QA
  module Page
    module Group
      module Milestone
        class Index < Page::Milestone::Index
          view 'app/views/groups/milestones/index.html.haml' do
            element :new_group_milestone_link
          end

          def click_new_milestone_link
            click_element(:new_group_milestone_link)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

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

QA::Page::Project::Milestone::Index.prepend_if_ee('QA::EE::Page::Project::Milestone::Index')

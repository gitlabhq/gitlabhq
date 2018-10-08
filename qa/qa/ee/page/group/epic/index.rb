# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Epic
          class Index < QA::Page::Base
            view 'ee/app/assets/javascripts/epics/new_epic/components/new_epic.vue' do
              element :new_epic_button
              element :epic_title
              element :create_epic_button
            end

            def click_new_epic
              click_element :new_epic_button
            end

            def set_title(title)
              fill_element :epic_title, title
            end

            def create_new_epic
              click_element :create_epic_button
            end
          end
        end
      end
    end
  end
end

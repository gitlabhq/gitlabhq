# frozen_string_literal: true

module QA
  module Page
    module Project
      module Issue
        class New < Page::Issuable::New
          view 'app/views/shared/issuable/_form.html.haml' do
            element :issuable_create_button
          end

          def create_new_issue
            click_element :issuable_create_button, Page::Project::Issue::Show
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module QA
  module Page
    module Project
      module Issue
        class New < Page::Issuable::New
          view 'app/views/shared/issuable/_form.html.haml' do
            element 'issuable-create-button'
          end

          def create_new_issue
            click_element('issuable-create-button', Page::Project::Issue::Show)
          end
        end
      end
    end
  end
end

QA::Page::Project::Issue::New.prepend_mod_with('Page::Project::Issue::New', namespace: QA)

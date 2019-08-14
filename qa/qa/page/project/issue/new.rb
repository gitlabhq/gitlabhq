# frozen_string_literal: true

module QA
  module Page
    module Project
      module Issue
        class New < Page::Base
          view 'app/views/shared/issuable/_form.html.haml' do
            element :issuable_create_button
          end

          view 'app/views/shared/issuable/form/_title.html.haml' do
            element :issue_title_textbox, 'form.text_field :title' # rubocop:disable QA/ElementWithPattern
          end

          view 'app/views/shared/form_elements/_description.html.haml' do
            element :issue_description_textarea, "render 'projects/zen', f: form, attr: :description" # rubocop:disable QA/ElementWithPattern
          end

          def add_title(title)
            fill_in 'issue_title', with: title
          end

          def add_description(description)
            fill_in 'issue_description', with: description
          end

          def create_new_issue
            click_element :issuable_create_button, Page::Project::Issue::Show
          end
        end
      end
    end
  end
end

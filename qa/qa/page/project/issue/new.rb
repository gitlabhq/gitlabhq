module QA
  module Page
    module Project
      module Issue
        class New < Page::Base
          view 'app/views/shared/issuable/_form.html.haml' do
            element :submit_issue_button, 'form.submit "Submit'
          end

          view 'app/views/shared/issuable/form/_title.html.haml' do
            element :issue_title_textbox, 'form.text_field :title'
          end

          view 'app/views/shared/form_elements/_description.html.haml' do
            element :issue_description_textarea, "render 'projects/zen', f: form, attr: :description"
          end

          def add_title(title)
            fill_in 'issue_title', with: title
          end

          def add_description(description)
            fill_in 'issue_description', with: description
          end

          def create_new_issue
            click_on 'Submit issue'
          end
        end
      end
    end
  end
end

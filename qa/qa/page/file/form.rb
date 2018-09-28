module QA
  module Page
    module File
      class Form < Page::Base
        include Shared::CommitMessage

        view 'app/views/projects/blob/_editor.html.haml' do
          element :file_name, "text_field_tag 'file_name'"
          element :editor, '#editor'
        end

        view 'app/views/projects/_commit_button.html.haml' do
          element :commit_changes, "button_tag 'Commit changes'"
        end

        def add_name(name)
          fill_in 'file_name', with: name
        end

        def add_content(content)
          text_area.set content
        end

        def remove_content
          text_area.send_keys([:command, 'a'], :backspace)
        end

        def commit_changes
          click_on 'Commit changes'
        end

        private

        def text_area
          find('#editor>textarea', visible: false)
        end
      end
    end
  end
end

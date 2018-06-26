module QA
  module Page
    module File
      class New < Page::Base

        def add_name_of_file(name)
          fill_in 'file_name', with: name
        end

        def add_file_content(content)
          find('.ace_text-input', visible: :all).set content
        end

        def add_commit_message(message)
          fill_in 'commit_message', with: message
        end

        def commit_changes
          click_on 'Commit changes'
        end

      end
    end
  end
end

module QA
  module Page
    module File
      class New < Page::Base

        def add_name(name)
          fill_in 'file_name', with: name
        end

        def add_content(content)
          find('.ace_text-input', visible: false).set content
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

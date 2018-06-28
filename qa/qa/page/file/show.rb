module QA
  module Page
    module File
      class Show < Page::Base

        def edit
          click_on 'Edit'
        end

        def delete
          click_on 'Delete'
        end

        def delete_file
          click_on 'Delete file'
        end

        def remove_content
          find('.ace_text-input', visible: false).send_keys([:command, 'a'], :backspace)
        end

        def update_content(content)
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

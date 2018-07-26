module QA
  module Page
    module File
      class Show < Page::Base
        include Shared::CommitMessage

        view 'app/helpers/blob_helper.rb' do
          element :edit_button, "_('Edit')"
          element :delete_button, /label:\s+"Delete"/
        end

        view 'app/views/projects/blob/_remove.html.haml' do
          element :delete_file_button, "button_tag 'Delete file'"
        end

        def click_edit
          click_on 'Edit'
        end

        def click_delete
          click_on 'Delete'
        end

        def click_delete_file
          click_on 'Delete file'
        end
      end
    end
  end
end

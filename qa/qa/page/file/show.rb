module QA
  module Page
    module File
      class Show < Page::Base
        include Shared::CommitMessage

        view 'app/helpers/blob_helper.rb' do
          element :edit_button, "_('Edit')" # rubocop:disable QA/ElementWithPattern
          element :delete_button, '_("Delete")' # rubocop:disable QA/ElementWithPattern
        end

        view 'app/views/projects/blob/_remove.html.haml' do
          element :delete_file_button, "button_tag 'Delete file'" # rubocop:disable QA/ElementWithPattern
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

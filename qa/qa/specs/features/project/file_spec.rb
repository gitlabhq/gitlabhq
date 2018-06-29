module QA
  feature 'Create, edit and delete file in project', :core do
    scenario 'User creates, edits and deletes a file' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act {sign_in_using_credentials}

      file_name = 'QA Test - File name'
      file_content = 'QA Test - File content'
      commit_message_for_create = 'QA Test - Create new file'

      Factory::Resource::File.fabricate! do |file|
        file.name = file_name
        file.content = file_content
        file.commit_message = commit_message_for_create
      end

      expect(page).to have_content('The file has been successfully created.')
      expect(page).to have_content(file_name)
      expect(page).to have_content(file_content)
      expect(page).to have_content(commit_message_for_create)

      updated_file_content = 'QA Test - Updated file content'
      commit_message_for_update = 'QA Test - Update file'

      Page::File::Show.act {click_edit}

      Page::File::Edit.act do
        remove_content
        update_content(updated_file_content)
        add_commit_message(commit_message_for_update)
        commit_changes
      end

      expect(page).to have_content('Your changes have been successfully committed.')
      expect(page).to have_content(updated_file_content)
      expect(page).to have_content(commit_message_for_update)

      commit_message_for_delete = 'QA Test - Delete file'

      Page::File::Show.act do
        click_delete
        add_commit_message(commit_message_for_delete)
        click_delete_file
      end

      expect(page).to have_content('The file has been successfully deleted.')
      expect(page).to have_content(commit_message_for_delete)
      expect(page).to have_no_content(file_name)
    end
  end
end

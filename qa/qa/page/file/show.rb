# frozen_string_literal: true

module QA
  module Page
    module File
      class Show < Page::Base
        include Shared::CommitMessage
        include Project::SubMenus::Settings
        include Project::SubMenus::Common
        include Layout::Flash

        view 'app/helpers/blob_helper.rb' do
          element :edit_button, "_('Edit')" # rubocop:disable QA/ElementWithPattern
          element :delete_button, '_("Delete")' # rubocop:disable QA/ElementWithPattern
        end

        view 'app/views/projects/blob/_header_content.html.haml' do
          element :file_name_content
        end

        view 'app/views/projects/blob/_remove.html.haml' do
          element :delete_file_button, "button_tag 'Delete file'" # rubocop:disable QA/ElementWithPattern
        end

        view 'app/views/shared/_file_highlight.html.haml' do
          element :file_content
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

        def has_file?(name)
          has_element?(:file_name_content, text: name)
        end

        def has_no_file?(name)
          has_no_element?(:file_name_content, text: name)
        end

        def has_file_content?(file_content, file_number = nil)
          if file_number
            within_element_by_index(:file_content, file_number - 1) do
              has_text?(file_content)
            end
          else
            within_element(:file_content) do
              has_text?(file_content)
            end
          end
        end
      end
    end
  end
end

QA::Page::File::Show.prepend_mod_with('Page::File::Show', namespace: QA)

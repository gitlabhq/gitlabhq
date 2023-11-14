# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class ProtectedTags < Page::Base
          include Page::Component::DropdownFilter

          view 'app/views/projects/protected_tags/shared/_dropdown.html.haml' do
            element 'tags-dropdown'
          end

          view 'app/assets/javascripts/protected_tags/protected_tag_create.js' do
            element 'allowed-to-create-dropdown'
          end

          view 'app/views/projects/protected_tags/shared/_create_protected_tag.html.haml' do
            element 'protect-tag-button'
          end

          def set_tag(tag_name)
            click_button 'Add tag'
            click_element 'tags-dropdown'
            filter_and_select(tag_name)
          end

          def choose_access_level_role(role)
            return if find_element('allowed-to-create-dropdown').text == role

            click_element 'allowed-to-create-dropdown'
            within_element 'allowed-to-create-dropdown' do
              click_on role
            end
            # confirm selection and remove dropdown
            click_element 'allowed-to-create-dropdown'
          end

          def click_protect_tag_button
            click_element 'protect-tag-button'
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::ProtectedTags.prepend_mod_with('Page::Project::Settings::ProtectedTags', namespace: QA)

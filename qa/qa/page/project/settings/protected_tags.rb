# frozen_string_literal: true

module QA
  module Page
    module Project
      module Settings
        class ProtectedTags < Page::Base
          include Page::Component::DropdownFilter

          view 'app/views/projects/protected_tags/shared/_dropdown.html.haml' do
            element :tags_dropdown
          end

          view 'app/assets/javascripts/protected_tags/protected_tag_create.js' do
            element :allowed_to_create_dropdown
          end

          view 'app/views/projects/protected_tags/shared/_create_protected_tag.html.haml' do
            element :protect_tag_button
          end

          def set_tag(tag_name)
            click_button 'Add tag'
            click_element :tags_dropdown
            filter_and_select(tag_name)
          end

          def choose_access_level_role(role)
            return if find_element(:allowed_to_create_dropdown).text == role

            click_element :allowed_to_create_dropdown
            within_element :allowed_to_create_dropdown do
              click_on role
            end
            # confirm selection and remove dropdown
            click_element :allowed_to_create_dropdown
          end

          def click_protect_tag_button
            click_element :protect_tag_button
          end
        end
      end
    end
  end
end

QA::Page::Project::Settings::ProtectedTags.prepend_mod_with('Page::Project::Settings::ProtectedTags', namespace: QA)

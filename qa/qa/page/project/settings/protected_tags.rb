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

          view 'app/views/projects/protected_tags/_create_protected_tag.html.haml' do
            element :access_levels_content
            element :access_levels_dropdown
          end

          view 'app/views/projects/protected_tags/shared/_create_protected_tag.html.haml' do
            element :protect_tag_button
          end

          def set_tag(tag_name)
            click_element :tags_dropdown
            filter_and_select(tag_name)
          end

          def choose_access_level_role(role)
            return if find_element(:access_levels_dropdown).text == role

            click_element :access_levels_dropdown
            within_element(:access_levels_content) do
              click_on role
            end
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

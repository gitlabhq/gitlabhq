# frozen_string_literal: true

module QA
  module Page
    module Group
      class New < Page::Base
        include Page::Component::VisibilitySetting

        view 'app/views/shared/_group_form.html.haml' do
          element :group_path_field
          element :group_name_field
        end

        view 'app/views/groups/_new_group_fields.html.haml' do
          element :create_group_button, "submit _('Create group')" # rubocop:disable QA/ElementWithPattern
        end

        def set_path(path)
          fill_element(:group_path_field, path)
          fill_element(:group_name_field, path)
        end

        def create
          click_button 'Create group'
        end
      end
    end
  end
end

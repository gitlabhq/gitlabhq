# frozen_string_literal: true

module QA
  module Page
    module Group
      class New < Page::Base
        view 'app/views/shared/_group_form.html.haml' do
          element :group_path_field, 'text_field :path' # rubocop:disable QA/ElementWithPattern
          element :group_name_field, 'text_field :name' # rubocop:disable QA/ElementWithPattern
          element :group_description_field, 'text_area :description' # rubocop:disable QA/ElementWithPattern
        end

        view 'app/views/groups/_new_group_fields.html.haml' do
          element :create_group_button, "submit _('Create group')" # rubocop:disable QA/ElementWithPattern
          element :visibility_radios, 'visibility_level:' # rubocop:disable QA/ElementWithPattern
        end

        def set_path(path)
          fill_in 'group_path', with: path
          fill_in 'group_name', with: path
        end

        def set_description(description)
          fill_in 'group_description', with: description
        end

        def set_visibility(visibility)
          choose visibility
        end

        def create
          click_button 'Create group'
        end
      end
    end
  end
end

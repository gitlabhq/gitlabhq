module QA
  module Page
    module Group
      class New < Page::Base
        view 'app/views/shared/_group_form.html.haml' do
          element :group_path_field, 'text_field :path'
          element :group_name_field, 'text_field :name'
          element :group_description_field, 'text_area :description'
        end

        view 'app/views/groups/new.html.haml' do
          element :create_group_button, "submit 'Create group'"
          element :visibility_radios, 'visibility_level:'
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

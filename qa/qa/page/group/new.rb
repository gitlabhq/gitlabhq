module QA
  module Page
    module Group
      class New < Page::Base
        def set_path(path)
          fill_in 'group_path', with: path
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

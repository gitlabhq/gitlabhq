module QA
  module Page
    module Group
      class New < Page::Base
        def create_group(group_name = nil, group_description = nil)
          if page.has_content?('New Subgroup')
            click_on 'New Subgroup'
          else
            click_on 'New group'
          end

          group_name ||= Runtime::Namespace.name
          group_description ||= "QA test run at #{Runtime::Namespace.name}"

          fill_in 'group_path', with: group_name
          fill_in 'group_description', with: group_description
          choose 'Private'

          click_button 'Create group'
        end
      end
    end
  end
end

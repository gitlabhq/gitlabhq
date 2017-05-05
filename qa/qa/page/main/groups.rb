module QA
  module Page
    module Main
      class Groups < Page::Base
        def prepare_test_namespace
          return if page.has_content?(Runtime::Namespace.name)

          click_on 'New group'

          fill_in 'group_path', with: Runtime::Namespace.name
          fill_in 'group_description',
                  with: "QA test run at #{Runtime::Namespace.time}"
          choose 'Private'

          click_button 'Create group'
        end
      end
    end
  end
end

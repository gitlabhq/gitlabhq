module QA
  module Page
    module Dashboard
      class Groups < Page::Base
        def prepare_sandbox
          sandbox_name = Runtime::Namespace.sandbox_name

          fill_in 'Filter by name...', with: sandbox_name

          if page.has_content?(sandbox_name)
            return click_link(sandbox_name)
          else
            click_on 'New group'

            populate_group_form(sandbox_name, "QA sandbox")
          end
        end

        def prepare_test_namespace
          namespace_name = Runtime::Namespace.name

          if page.has_content?('Subgroups')
            click_link 'Subgroups'

            if page.has_content?(namespace_name)
              return click_link(namespace_name)
            end

            # NOTE: Inconsistent capitalization here in the UI
            click_on 'New Subgroup'
          else
            click_on 'New group'
          end

          populate_group_form(
            namespace_name,
            "QA test run at #{Runtime::Namespace.time}"
          )
        end

        private

        def populate_group_form(name, description)
          fill_in 'group_path', with: name
          fill_in 'group_description', with: description
          choose 'Private'

          click_button 'Create group'
        end
      end
    end
  end
end

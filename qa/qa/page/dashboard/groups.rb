module QA
  module Page
    module Dashboard
      class Groups < Page::Base
        def filter_by_name(name)
          # NOTE: The filter placeholder on the Subgroups page currently omits
          # the ellipsis.
          #
          # See https://gitlab.com/gitlab-org/gitlab-ce/issues/38807
          if page.has_field?('Filter by name...')
            fill_in 'Filter by name...', with: name
          elsif page.has_field?('Filter by name')
            fill_in 'Filter by name', with: name
          end
        end

        def has_test_namespace?
          filter_by_name(namespace.name)

          page.has_link?(namespace.name)
        end

        def has_sandbox?
          filter_by_name(namespace.sandbox_name)

          page.has_link?(namespace.sandbox_name)
        end

        def go_to_test_namespace
          click_link namespace.name
        end

        def go_to_sandbox
          click_link namespace.sandbox_name
        end

        def create_group(group_name = nil, group_description = nil)
          Page::Group::New.act { create_group(group_name, group_description) }
        end

        def prepare_test_namespace
          if has_test_namespace?
            go_to_test_namespace
          else
            create_group
          end
        end

        private

        def namespace
          Runtime::Namespace
        end
      end
    end
  end
end

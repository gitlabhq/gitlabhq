module QA
  module Scenario
    module Gitlab
      module Sandbox
        # Ensure we're in our sandbox namespace, either by navigating to it or
        # by creating it if it doesn't yet exist
        class Prepare < Scenario::Template
          def perform
            Page::Main::Menu.act { go_to_groups }

            Page::Dashboard::Groups.perform do |page|
              if page.has_group?(Runtime::Namespace.sandbox_name)
                page.go_to_group(Runtime::Namespace.sandbox_name)
              else
                page.go_to_new_group

                Scenario::Gitlab::Group::Create.perform do |group|
                  group.path = Runtime::Namespace.sandbox_name
                  group.description = 'QA sandbox'
                end
              end
            end
          end
        end
      end
    end
  end
end

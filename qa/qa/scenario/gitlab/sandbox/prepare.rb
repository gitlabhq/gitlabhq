module QA
  module Scenario
    module Gitlab
      module Sandbox
        class Prepare < Scenario::Template
          def perform
            Page::Main::Menu.act { go_to_groups }

            Page::Dashboard::Groups.perform do |page|
              if page.has_sandbox?
                page.go_to_sandbox
              else
                page.create_group(Runtime::Namespace.sandbox_name, "QA sandbox")
              end
            end

            Page::Group::Show.act { go_to_subgroups }
          end
        end
      end
    end
  end
end

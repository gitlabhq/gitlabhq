require 'securerandom'

module QA
  module Scenario
    module Gitlab
      module Project
        class Create < Scenario::Template
          attr_writer :description

          def name=(name)
            @name = "#{name}-#{SecureRandom.hex(8)}"
          end

          def perform
            Page::Main::Menu.act { go_to_groups }
            Page::Dashboard::Groups.act { prepare_test_namespace }
            Page::Group::Show.act { go_to_new_project }

            Page::Project::New.perform do |page|
              page.choose_test_namespace
              page.choose_name(@name)
              page.add_description(@description)
              page.create_new_project
            end
          end
        end
      end
    end
  end
end

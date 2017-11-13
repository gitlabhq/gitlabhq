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
            Scenario::Gitlab::Sandbox::Prepare.perform

            Page::Group::Show.perform do |page|
              if page.has_subgroup?(Runtime::Namespace.name)
                page.go_to_subgroup(Runtime::Namespace.name)
              else
                page.go_to_new_subgroup

                Scenario::Gitlab::Group::Create.perform do |group|
                  group.path = Runtime::Namespace.name
                end
              end

              page.go_to_new_project
            end

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

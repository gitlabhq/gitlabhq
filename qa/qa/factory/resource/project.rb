require 'securerandom'

module QA
  module Factory
    module Resource
      class Project < Factory::Base
        attr_writer :description

        def name=(name)
          @name = "#{name}-#{SecureRandom.hex(8)}"
        end

        def fabricate!
          Factory::Resource::Sandbox.fabricate!

          Page::Group::Show.perform do |page|
            if page.has_subgroup?(Runtime::Namespace.name)
              page.go_to_subgroup(Runtime::Namespace.name)
            else
              page.go_to_new_subgroup

              Factory::Resource::Group.fabricate! do |group|
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

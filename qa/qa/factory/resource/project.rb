require 'securerandom'

module QA
  module Factory
    module Resource
      class Project < Factory::Base
        attr_writer :description

        dependency Factory::Resource::Group, as: :group

        def name=(name)
          @name = "#{name}-#{SecureRandom.hex(8)}"
          @description = 'My awesome project'
        end

        product :name do
          Page::Project::Show.act { project_name }
        end

        product :repository_ssh_location do
          Page::Project::Show.act do
            choose_repository_clone_ssh
            repository_location
          end
        end

        def fabricate!
          group.visit!

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

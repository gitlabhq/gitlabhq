require 'securerandom'

module QA
  module Factory
    module Resource
      class Project < Factory::Base
        attr_writer :description
        attr_reader :name

        dependency Factory::Resource::Group, as: :group

        product :name do |factory|
          factory.name
        end

        product :repository_ssh_location do
          Page::Project::Show.act do
            choose_repository_clone_ssh
            repository_location
          end
        end

        def initialize
          @description = 'My awesome project'
        end

        def name=(raw_name)
          @name = "#{raw_name}-#{SecureRandom.hex(8)}"
        end

        def fabricate!
          group.visit!

          Page::Group::Show.act { go_to_new_project }

          Page::Project::New.perform do |page|
            page.choose_test_namespace
            page.choose_name(@name)
            page.add_description(@description)
            page.set_visibility('Public')
            page.create_new_project
          end
        end
      end
    end
  end
end

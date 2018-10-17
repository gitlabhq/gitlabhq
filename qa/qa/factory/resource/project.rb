require 'securerandom'

module QA
  module Factory
    module Resource
      class Project < Factory::Base
        attr_accessor :description
        attr_reader :name

        dependency Factory::Resource::Group, as: :group

        product :group
        product :name

        product :repository_ssh_location do
          Page::Project::Show.act do
            choose_repository_clone_ssh
            repository_location
          end
        end

        product :repository_http_location do
          Page::Project::Show.act do
            choose_repository_clone_http
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

        def api_get_path
          "/projects/#{name}"
        end

        def api_post_path
          '/projects'
        end

        def api_post_body
          {
            namespace_id: group.id,
            path: name,
            name: name,
            description: description,
            visibility: 'public'
          }
        end

        private

        def transform_api_resource(resource)
          resource[:repository_ssh_location] = Git::Location.new(resource[:ssh_url_to_repo])
          resource[:repository_http_location] = Git::Location.new(resource[:http_url_to_repo])
          resource
        end
      end
    end
  end
end

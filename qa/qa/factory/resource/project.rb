require 'securerandom'

module QA
  module Factory
    module Resource
      class Project < Factory::Base
        attr_accessor :description
        attr_reader :name, :api_object

        dependency Factory::Resource::Group, as: :group

        product :name do |factory|
          factory.api_object ? factory.api_object[:name] : factory.name
        end

        product :repository_ssh_location do |factory|
          if factory.api_object
            factory.api_object[:ssh_url_to_repo]
          else
            Page::Project::Show.act do
              choose_repository_clone_ssh
              repository_location
            end
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

        def api_get
          response = get(Runtime::API::Request.new(api_client, "/projects/#{name}").url)
          JSON.parse(response.body, symbolize_names: true)
        end

        def api_post!
          response = post(
            Runtime::API::Request.new(api_client, '/projects').url,
            namespace_id: group.id,
            path: name,
            name: name,
            description: description)
          JSON.parse(response.body, symbolize_names: true)
        end

        def fabricate_via_api!
          @api_object = api_post!
          @api_object[:web_url]
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

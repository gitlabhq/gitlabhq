module QA
  module Factory
    module Resource
      ##
      # Ensure we're in our sandbox namespace, either by navigating to it or by
      # creating it if it doesn't yet exist.
      #
      class Sandbox < Factory::Base
        attr_reader :path, :api_object

        product :id do |factory|
          factory.api_object ? factory.api_object[:id] : raise("unknown id")
        end

        def initialize
          @path = Runtime::Namespace.sandbox_name
        end

        def api_get
          response = get(Runtime::API::Request.new(api_client, "/groups/#{path}").url)
          JSON.parse(response.body, symbolize_names: true)
        end

        def api_post!
          response = post(
            Runtime::API::Request.new(api_client, '/groups').url,
            path: path,
            name: path)
          JSON.parse(response.body, symbolize_names: true)
        end

        def fabricate_via_api!
          sandbox_object = api_get

          if sandbox_object.key?(:web_url)
            @api_object = sandbox_object

            return sandbox_object[:web_url]
          end

          @api_object = api_post!
          @api_object[:web_url]
        end

        def fabricate!
          Page::Main::Menu.act { go_to_groups }

          Page::Dashboard::Groups.perform do |page|
            if page.has_group?(path)
              page.go_to_group(path)
            else
              page.go_to_new_group

              Page::Group::New.perform do |group|
                group.set_path(path)
                group.set_description('GitLab QA Sandbox Group')
                group.set_visibility('Public')
                group.create
              end
            end
          end
        end
      end
    end
  end
end

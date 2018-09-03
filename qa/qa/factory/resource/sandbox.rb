module QA
  module Factory
    module Resource
      ##
      # Ensure we're in our sandbox namespace, either by navigating to it or by
      # creating it if it doesn't yet exist.
      #
      class Sandbox < Factory::Base
        attr_reader :path

        product :id do |factory|
          factory.api_resource ? factory.api_resource[:id] : raise('Unknown id')
        end

        product :path do |factory|
          factory.path
        end

        def initialize
          @path = Runtime::Namespace.sandbox_name
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

        def api_get_path
          "/groups/#{path}"
        end

        def api_post_path
          '/groups'
        end

        def api_post_body
          {
            path: path,
            name: path,
            visibility: 'public'
          }
        end
      end
    end
  end
end

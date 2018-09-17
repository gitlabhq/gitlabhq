module QA
  module Factory
    module Resource
      ##
      # Ensure we're in our sandbox namespace, either by navigating to it or by
      # creating it if it doesn't yet exist.
      #
      class Sandbox < Factory::Base
        attr_reader :group_path

        product :id

        product :path

        def initialize
          @group_path = Runtime::Namespace.sandbox_name
        end

        def fabricate!
          Page::Main::Menu.act { go_to_groups }

          Page::Dashboard::Groups.perform do |page|
            if page.has_group?(group_path)
              page.go_to_group(group_path)
            else
              page.go_to_new_group

              Page::Group::New.perform do |group|
                group.set_path(group_path)
                group.set_description('GitLab QA Sandbox Group')
                group.set_visibility('Public')
                group.create
              end
            end
          end
        end

        def api_get_path
          "/groups/#{group_path}"
        end

        def api_post_path
          '/groups'
        end

        def api_post_body
          {
            path: group_path,
            name: group_path,
            visibility: 'public'
          }
        end
      end
    end
  end
end

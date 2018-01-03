module QA
  module Factory
    module Resource
      ##
      # Ensure we're in our sandbox namespace, either by navigating to it or by
      # creating it if it doesn't yet exist.
      #
      class Sandbox < Factory::Base
        def initialize
          @name = Runtime::Namespace.sandbox_name
        end

        def fabricate!
          Page::Menu::Main.act { go_to_groups }

          Page::Dashboard::Groups.perform do |page|
            if page.has_group?(@name)
              page.go_to_group(@name)
            else
              page.go_to_new_group

              Page::Group::New.perform do |group|
                group.set_path(@name)
                group.set_description('GitLab QA Sandbox')
                group.set_visibility('Private')
                group.create
              end
            end
          end
        end
      end
    end
  end
end

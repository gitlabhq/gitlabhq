module QA
  module Factory
    module Settings
      class HashedStorage < Factory::Base
        def fabricate!(*traits)
          raise ArgumentError unless traits.include?(:enabled)

          Page::Main::Login.act { sign_in_using_credentials }
          Page::Main::Menu.act { go_to_admin_area }
          Page::Admin::Menu.act { go_to_repository_settings }

          Page::Admin::Settings::Repository.perform do |setting|
            setting.expand_repository_storage do |page|
              page.enable_hashed_storage
              page.save_settings
            end
          end

          QA::Page::Main::Menu.act { sign_out }
        end
      end
    end
  end
end

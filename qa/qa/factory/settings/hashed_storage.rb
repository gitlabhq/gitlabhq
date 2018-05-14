module QA
  module Factory
    module Settings
      class HashedStorage < Factory::Base
        def fabricate!(*traits)
          raise ArgumentError unless traits.include?(:enabled)

          Page::Main::Login.act { sign_in_using_credentials }
          Page::Menu::Main.act { go_to_admin_area }
          Page::Menu::Admin.act { go_to_settings }

          Page::Admin::Settings::Main.perform do |setting|
            setting.expand_repository_storage do |page|
              page.enable_hashed_storage
              page.save_settings
            end
          end

          QA::Page::Menu::Main.act { sign_out }
        end
      end
    end
  end
end

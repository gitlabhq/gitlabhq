module QA
  module Factory
    module Settings
      class HashedStorage < Factory::Base
        def fabricate!(*traits)
          raise ArgumentError unless traits.include?(:enabled)

          Page::Main::Login.act { sign_in_using_credentials }
          Page::Menu::Main.act { go_to_admin_area }
          Page::Menu::Admin.act { go_to_settings }

          Page::Admin::Settings.act do
            enable_hashed_storage
            save_settings
          end

          QA::Page::Menu::Main.act { sign_out }
        end
      end
    end
  end
end

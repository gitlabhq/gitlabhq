module QA
  module Scenario
    module Gitlab
      module Admin
        class HashedStorage < Scenario::Template
          def perform(*traits)
            raise ArgumentError unless traits.include?(:enabled)

            Page::Main::Entry.act { visit_login_page }
            Page::Main::Login.act { sign_in_using_credentials }
            Page::Main::Menu.act { go_to_admin_area }
            Page::Admin::Menu.act { go_to_settings }

            Page::Admin::Settings.act do
              enable_hashed_storage
              save_settings
            end

            QA::Page::Main::Menu.act { sign_out }
          end
        end
      end
    end
  end
end

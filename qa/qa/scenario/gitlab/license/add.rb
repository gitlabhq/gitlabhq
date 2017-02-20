module QA
  module Scenario
    module Gitlab
      module License
        class Add < Scenario::Template
          def perform
            Page::Main::Entry.act { sign_in_using_credentials }
            Page::Main::Menu.act { go_to_admin_area }
            Page::Admin::Menu.act { go_to_license }

            Page::Admin::License.act do
              add_new_license(ENV['EE_LICENSE']) if no_license?
            end

            Page::Main::Menu.act { sign_out }
          end
        end
      end
    end
  end
end

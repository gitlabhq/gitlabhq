module QA
  module EE
    module Scenario
      module License
        class Add < QA::Scenario::Template
          def perform(license)
            QA::Page::Main::Entry.act { visit_login_page }
            QA::Page::Main::Login.act { sign_in_using_credentials }
            QA::Page::Main::Menu.act { go_to_admin_area }
            QA::Page::Admin::Menu.act { go_to_license }

            EE::Page::Admin::License.act(license) do |key|
              add_new_license(key) if no_license?
            end

            QA::Page::Main::Menu.act { sign_out }
          end
        end
      end
    end
  end
end

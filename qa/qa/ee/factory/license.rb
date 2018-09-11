module QA
  module EE
    module Factory
      class License < QA::Factory::Base
        def fabricate!(license)
          QA::Page::Main::Login.act { sign_in_using_admin_credentials }
          QA::Page::Menu::Main.act { go_to_admin_area }
          QA::Page::Menu::Admin.act { go_to_license }

          EE::Page::Admin::License.act(license) do |key|
            add_new_license(key) if no_license?
          end

          QA::Page::Menu::Main.act { sign_out }
        end
      end
    end
  end
end

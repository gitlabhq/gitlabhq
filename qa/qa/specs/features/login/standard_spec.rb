module QA
  feature 'standard root login', :core do
    scenario 'user logs in using credentials' do
      Page::Main::Entry.act { visit_login_page }
      Page::Main::Login.act { sign_in_using_credentials }

      # TODO, since `Signed in successfully` message was removed
      # this is the only way to tell if user is signed in correctly.
      #
      Page::Main::Menu.perform do |menu|
        expect(menu).to have_personal_area
      end
    end
  end
end

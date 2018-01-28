module QA
  feature 'create a new group', :mattermost do
    scenario 'creating a group with a mattermost team' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }
      Page::Menu::Main.act { go_to_groups }

      Page::Dashboard::Groups.perform do |page|
        page.go_to_new_group

        expect(page).to have_content(
          /Create a Mattermost team for this group/
        )
      end
    end
  end
end

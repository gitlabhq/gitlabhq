module QA
  feature 'create a new group' do
    scenario 'creating a group with a mattermost team', :mattermost do
      Page::Main::Entry.act { sign_in_using_credentials }
      Page::Main::Menu.act { go_to_groups }

      Page::Dashboard::Groups.perform do |page|
        page.go_to_new_group

        expect(page).to have_content(
          /Create a Mattermost team for this group/
        )
      end
    end
  end
end

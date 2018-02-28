module QA
  feature 'logging in to Mattermost', :mattermost do
    scenario 'can use gitlab oauth' do
      Page::Main::Entry.act { sign_in_using_credentials }
      Page::Mattermost::Login.act { sign_in_using_oauth }

      Page::Mattermost::Main.perform do |page|
        expect(page).to have_content(/(Welcome to: Mattermost|Logout GitLab Mattermost)/)
      end
    end
  end
end

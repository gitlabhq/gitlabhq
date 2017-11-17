module QA
  feature 'logging in to Mattermost', :mattermost do
    scenario 'can use gitlab oauth' do
      Runtime::Browser.visit(Page::Gitlab::Login) do
        Page::Main::Login.act { sign_in_using_credentials }

        Runtime::Browser.visit(Page::Mattermost::Login) do
          Page::Mattermost::Login.act { sign_in_using_oauth }

          Page::Mattermost::Main.perform do |page|
            expect(page).to have_content(/(Welcome to: Mattermost|Logout GitLab Mattermost)/)
          end
        end
      end
    end
  end
end

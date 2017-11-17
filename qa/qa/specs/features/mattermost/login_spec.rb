module QA
  feature 'logging in to Mattermost', :mattermost do
    scenario 'can use gitlab oauth' do
      Runtime::Browser.session(Page::Gitlab::Login) do
        Page::Main::Login.act { sign_in_using_credentials }

        Runtime::Browser.session(Page::Mattermost::Login) do
          Page::Mattermost::Login.act { sign_in_using_oauth }

          Page::Mattermost::Main.perform do |page|
            expect(page).to have_content(/(Welcome to: Mattermost|Logout GitLab Mattermost)/)
          end
        end
      end
    end

    ##
    # TODO, temporary workaround for gitlab-org/gitlab-qa#102.
    #
    after do
      visit Runtime::Scenario.mattermost_address
      reset_session!

      visit Runtime::Scenario.gitlab_address
      reset_session!
    end
  end
end

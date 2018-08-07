module QA
  describe 'user imports a GitHub repo', :orchestrated, :github do
    let(:imported_project) do
      Factory::Resource::ProjectImportedFromGithub.fabricate! do |project|
        project.name = 'imported-project'
        project.personal_access_token = Runtime::Env.github_access_token
        project.github_repository_path = 'gitlab-qa/test-project'
      end
    end

    after do
      # We need to delete the imported project because it's impossible to import
      # the same GitHub project twice for a given user.
      api_client = Runtime::API::Client.new(:gitlab)
      delete_project_request = Runtime::API::Request.new(api_client, "/projects/#{CGI.escape("#{Runtime::Namespace.path}/#{imported_project.name}")}")
      delete delete_project_request.url

      expect_status(202)
    end

    it 'user imports a GitHub repo' do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }

      imported_project # import the project

      Page::Menu::Main.act { go_to_projects }
      Page::Dashboard::Projects.perform do |dashboard|
        dashboard.go_to_project(imported_project.name)
      end

      Page::Project::Show.act { wait_for_import }

      verify_repository_import
      verify_issues_import
      verify_merge_requests_import
      verify_labels_import
      verify_milestones_import
      verify_wiki_import
    end

    def verify_repository_import
      expect(page).to have_content('This test project is used for automated GitHub import by GitLab QA.')
      expect(page).to have_content(imported_project.name)
    end

    def verify_issues_import
      Page::Menu::Side.act { click_issues }
      expect(page).to have_content('This is a sample issue')

      click_link 'This is a sample issue'

      expect(page).to have_content('We should populate this project with issues, pull requests and wiki pages.')

      # Comments
      expect(page).to have_content('This is a comment from @rymai.')

      Page::Issuable::Sidebar.perform do |issuable|
        expect(issuable).to have_label('enhancement')
        expect(issuable).to have_label('help wanted')
        expect(issuable).to have_label('good first issue')
      end
    end

    def verify_merge_requests_import
      Page::Menu::Side.act { click_merge_requests }
      expect(page).to have_content('Improve README.md')

      click_link 'Improve README.md'

      expect(page).to have_content('This improves the README file a bit.')

      # Review comment are not supported yet
      expect(page).not_to have_content('Really nice change.')

      # Comments
      expect(page).to have_content('Nice work! This is a comment from @rymai.')

      # Diff comments
      expect(page).to have_content('[Review comment] I like that!')
      expect(page).to have_content('[Review comment] Nice blank line.')
      expect(page).to have_content('[Single diff comment] Much better without this line!')

      Page::Issuable::Sidebar.perform do |issuable|
        expect(issuable).to have_label('bug')
        expect(issuable).to have_label('enhancement')
      end
    end

    def verify_labels_import
      # TODO: Waiting on https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/19228
      # to build upon it.
    end

    def verify_milestones_import
      # TODO: Waiting on https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/18727
      # to build upon it.
    end

    def verify_wiki_import
      Page::Menu::Side.act { click_wiki }

      expect(page).to have_content('Welcome to the test-project wiki!')
    end
  end
end

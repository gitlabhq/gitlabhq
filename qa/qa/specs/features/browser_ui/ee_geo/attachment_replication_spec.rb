module QA
  describe 'GitLab Geo attachment replication', :geo do
    let(:file_to_attach) { File.absolute_path(File.join('spec', 'fixtures', 'banana_sample.gif')) }

    it 'user uploads attachment to the primary node' do
      Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
        Page::Main::Login.act { sign_in_using_credentials }

        project = Factory::Resource::Project.fabricate! do |project|
          project.name = 'project-for-issues'
          project.description = 'project for adding issues'
        end

        issue = Factory::Resource::Issue.fabricate! do |issue|
          issue.title = 'My geo issue'
          issue.project = project
        end

        Page::Project::Issue::Show.perform do |show|
          show.comment('See attached banana for scale', attachment: file_to_attach)
        end

        Runtime::Browser.visit(:geo_secondary, QA::Page::Main::Login) do |session|
          Page::Main::OAuth.act do
            authorize! if needs_authorization?
          end

          EE::Page::Main::Banner.perform do |banner|
            expect(banner).to have_secondary_read_only_banner
          end

          expect(page).to have_content 'You are on a secondary, read-only Geo node'

          Page::Menu::Main.perform do |menu|
            menu.go_to_projects
          end

          Page::Dashboard::Projects.perform do |dashboard|
            dashboard.wait_for_project_replication(project.name)

            dashboard.go_to_project(project.name)
          end

          Page::Menu::Side.act { click_issues }

          Page::Project::Issue::Index.perform do |index|
            index.wait_for_issue_replication(issue)
          end

          image_url = find('a[href$="banana_sample.gif"]')[:href]

          Page::Project::Issue::Show.perform do |show|
            # Wait for attachment replication
            found = show.wait(reload: false) do
              show.asset_exists?(image_url)
            end

            expect(found).to be_truthy
          end
        end
      end
    end
  end
end

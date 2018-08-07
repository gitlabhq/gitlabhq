module QA
  describe 'GitLab Geo repository replication', :geo do
    it 'users pushes code to the primary node' do
      Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
        Page::Main::Login.act { sign_in_using_credentials }

        project = Factory::Resource::Project.fabricate! do |project|
          project.name = 'geo-project'
          project.description = 'Geo test project'
        end

        geo_project_name = Page::Project::Show.act { project_name }
        expect(geo_project_name).to include 'geo-project'

        Factory::Repository::ProjectPush.fabricate! do |push|
          push.file_name = 'README.md'
          push.file_content = '# This is Geo project!'
          push.commit_message = 'Add README.md'
          push.project = project
        end

        Runtime::Browser.visit(:geo_secondary, QA::Page::Main::Login) do
          Page::Main::OAuth.act do
            authorize! if needs_authorization?
          end

          EE::Page::Main::Banner.perform do |banner|
            expect(banner).to have_secondary_read_only_banner
          end

          Page::Menu::Main.perform do |menu|
            menu.go_to_projects
          end

          Page::Dashboard::Projects.perform do |dashboard|
            dashboard.wait_for_project_replication(geo_project_name)

            dashboard.go_to_project(geo_project_name)
          end

          Page::Project::Show.perform do |show|
            show.wait_for_repository_replication

            expect(page).to have_content 'README.md'
            expect(page).to have_content 'This is Geo project!'
          end
        end
      end
    end
  end
end

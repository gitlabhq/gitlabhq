module QA
  feature 'GitLab Geo project rename replication', :geo do
    scenario 'user renames project' do
      # create the project and push code
      Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
        Page::Main::Login.act { sign_in_using_credentials }

        project = Factory::Resource::Project.fabricate! do |project|
          project.name = 'geo-before-rename'
          project.description = 'Geo project to be renamed'
        end

        geo_project_name = project.name
        expect(project.name).to include 'geo-before-rename'

        Factory::Repository::Push.fabricate! do |push|
          push.project = project
          push.file_name = 'README.md'
          push.file_content = '# This is Geo project!'
          push.commit_message = 'Add README.md'
        end

        # rename the project
        Page::Menu::Main.act { go_to_projects }

        Page::Dashboard::Projects.perform do |dashboard|
          dashboard.go_to_project(geo_project_name)
        end

        Page::Menu::Side.act { go_to_settings }

        geo_project_renamed = "geo-after-rename-#{SecureRandom.hex(8)}"
        Page::Project::Settings::Main.perform do |settings|
          settings.expand_advanced_settings do |page|
            page.rename_to(geo_project_renamed)
          end
        end

        sleep 2 # wait for replication

        # check renamed project exist on secondary node
        Runtime::Browser.visit(:geo_secondary, QA::Page::Main::Login) do
          Page::Main::OAuth.act do
            authorize! if needs_authorization?
          end

          expect(page).to have_content 'You are on a secondary (read-only) Geo node'

          Page::Menu::Main.perform do |menu|
            menu.go_to_projects

            expect(page).to have_content(geo_project_renamed)
          end

          Page::Dashboard::Projects.perform do |dashboard|
            dashboard.go_to_project(geo_project_renamed)
          end

          Page::Project::Show.perform do
            expect(page).to have_content 'README.md'
            expect(page).to have_content 'This is Geo project!'
          end
        end
      end
    end
  end
end

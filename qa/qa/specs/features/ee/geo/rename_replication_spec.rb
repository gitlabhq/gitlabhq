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

        geo_project_name = Page::Project::Show.act { project_name }
        expect(geo_project_name).to include 'geo-before-rename'

        Factory::Repository::Push.fabricate! do |push|
          push.file_name = 'README.md'
          push.file_content = '# This is Geo project!'
          push.commit_message = 'Add README.md'
          push.project = project
        end

        # check it exists on the other machine
        visit(Runtime::Browser.url_for(:geo_secondary, QA::Page::Main::Login))
        Page::Main::OAuth.act do
          authorize! if needs_authorization?
        end

        expect(page).to have_content 'You are on a secondary (read-only) Geo node'

        Page::Menu::Main.perform do |menu|
          menu.go_to_projects

          expect(page).to have_content(geo_project_name)
        end

        sleep 10 # wait for repository replication

        Page::Dashboard::Projects.perform do |dashboard|
          dashboard.go_to_project(geo_project_name)
        end

        Page::Project::Show.perform do
          expect(page).to have_content 'README.md'
          expect(page).to have_content 'This is Geo project!'
        end

        # rename the project
        visit(Runtime::Browser.url_for(:geo_primary, QA::Page::Main::Home))
        Page::Menu::Main.act { go_to_projects }

        Page::Dashboard::Projects.perform do |dashboard|
          dashboard.go_to_project(geo_project_name)
        end

        Page::Project::Show.perform do |page|
          page.go_to_settings
        end

        geo_project_newname = "geo-after-rename-#{SecureRandom.hex(8)}"
        Page::Project::Settings::Main.perform do |page|
          page.expand_advanced_settings
          page.rename_to(geo_project_newname)
        end

        sleep 2 # wait for replication

        # check renamed project exist on secondary node
        visit(Runtime::Browser.url_for(:geo_secondary, QA::Page::Main::Home))

        expect(page).to have_content 'You are on a secondary (read-only) Geo node'

        Page::Menu::Main.perform do |menu|
          menu.go_to_projects

          expect(page).to have_content(geo_project_newname)
        end

        Page::Dashboard::Projects.perform do |dashboard|
          dashboard.go_to_project(geo_project_newname)
        end

        Page::Project::Show.perform do
          expect(page).to have_content 'README.md'
          expect(page).to have_content 'This is Geo project!'
        end
      end
    end
  end
end

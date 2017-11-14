module QA
  feature 'GitLab Geo replication', :geo do
    scenario 'users pushes code to the primary node' do
      Page::Main::Entry.act { visit(Runtime::Scenario.geo_primary_address) }
      Page::Main::Login.act { sign_in_using_credentials }

      Scenario::Gitlab::Project::Create.perform do |scenario|
        scenario.name = 'geo-project'
        scenario.description = 'Geo test project'
      end

      Git::Repository.perform do |repository|
        repository.location = Page::Project::Show.act do
          choose_repository_clone_http
          repository_location
        end

        repository.use_default_credentials

        repository.act do
          clone
          configure_identity('GitLab QA', 'root@gitlab.com')
          add_file('README.md', '# This is Geo project!')
          commit('Add README.md')
          push_changes
        end
      end

      Page::Main::Entry.act { visit(Runtime::Scenario.geo_secondary_address) }
      expect(page).to have_content 'You are on a secondary (read-only) Geo node'

      Page::Main::OAuth.act do
        if needs_authorization?
          expect(page).to have_content 'Authorize Geo node'

          authorize!
        end
      end

      Page::Main::Menu.act { go_to_projects }
      expect(page).to have_content 'geo-project'
    end
  end
end

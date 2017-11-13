module QA
  feature 'push code to repository', :core do
    context 'with regular account over http' do
      scenario 'user pushes code to the repository'  do
        Page::Main::Entry.act { visit_login_page }
        Page::Main::Login.act { sign_in_using_credentials }

        Scenario::Gitlab::Project::Create.perform do |scenario|
          scenario.name = 'project_with_code'
          scenario.description = 'project with repository'
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
            add_file('README.md', '# This is test project')
            commit('Add README.md')
            push_changes
          end
        end

        Page::Project::Show.act do
          wait_for_push
          refresh
        end

        expect(page).to have_content('README.md')
        expect(page).to have_content('This is test project')
      end
    end
  end
end

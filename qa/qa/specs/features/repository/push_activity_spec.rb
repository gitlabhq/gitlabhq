module QA
  feature 'push code to repository' do
    context 'with regular account over http' do
      scenario 'user can see their push in the project activity page' do
        Page::Main::Entry.act { sign_in_using_credentials }

        Scenario::Gitlab::Project::Create.perform do |scenario|
          scenario.name = 'project_with_code'
          scenario.description = 'project with repository'
        end

        push = Scenario::Gitlab::Repository::Push.perform do |scenario|
          scenario.add_file('README.md', '# This is test project')
          scenario.commit('Add README.md')
        end

        Page::Project::Show.act do
          wait_for_push
        end

        Page::Project::Activity.act do
          visit_activity_page
          filter_by_push_events
        end

        expect(page).to have_content('GitLab QA pushed to branch master')
        expect(page).to have_content(push.last_commit(:short))
        expect(page).to have_content(push.commit_title)
      end
    end
  end
end

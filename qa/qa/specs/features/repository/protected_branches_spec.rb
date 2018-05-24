module QA
  feature 'branch protection support', :core do
    given(:branch_name) { 'protected-branch' }
    given(:commit_message) { 'Protected push commit message' }
    given(:project) do
      Factory::Resource::Project.fabricate! do |resource|
        resource.name = 'protected-branch-project'
      end
    end
    given(:location) do
      Page::Project::Show.act do
        choose_repository_clone_http
        repository_location
      end
    end

    before do
      Runtime::Browser.visit(:gitlab, Page::Main::Login)
      Page::Main::Login.act { sign_in_using_credentials }
    end

    after do
      # We need to clear localStorage because we're using it for the dropdown,
      # and capybara doesn't do this for us.
      # https://github.com/teamcapybara/capybara/issues/1702
      Capybara.execute_script 'localStorage.clear()'
    end

    context 'when developers and maintainers are allowed to push to a protected branch' do
      let!(:protected_branch) { fabricate_branch(allow_to_push: true) }

      scenario 'user with push rights successfully pushes to the protected branch' do
        expect(protected_branch.name).to have_content(branch_name)
        expect(protected_branch.push_allowance).to have_content('Developers + Maintainers')

        project.visit!

        Git::Repository.perform do |repository|
          push_output = push_to_repository(repository)

          expect(push_output).to match(/remote: To create a merge request for protected-branch, visit/)
        end
      end
    end

    context 'when developers and maintainers are not allowed to push to a protected branch' do
      scenario 'user without push rights fails to push to the protected branch' do
        fabricate_branch(allow_to_push: false)

        project.visit!

        Git::Repository.perform do |repository|
          push_output = push_to_repository(repository)

          expect(push_output)
            .to match(/remote\: GitLab\: You are not allowed to push code to protected branches on this project/)
          expect(push_output)
            .to match(/\[remote rejected\] #{branch_name} -> #{branch_name} \(pre-receive hook declined\)/)
        end
      end
    end

    def fabricate_branch(allow_to_push:)
      Factory::Resource::Branch.fabricate! do |resource|
        resource.branch_name = branch_name
        resource.project = project
        resource.allow_to_push = allow_to_push
        resource.protected = true
      end
    end

    def push_to_repository(repository)
      repository.uri = location.uri
      repository.use_default_credentials

      repository.act do
        clone
        configure_identity('GitLab QA', 'root@gitlab.com')
        checkout('protected-branch')
        commit_file('README.md', 'readme content', 'Add a readme')
        push_changes('protected-branch')
        push_output
      end
    end
  end
end

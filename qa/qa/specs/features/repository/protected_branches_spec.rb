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

    scenario 'user is able to protect a branch' do
      protected_branch = Factory::Resource::Branch.fabricate! do |resource|
        resource.branch_name = branch_name
        resource.project = project
        resource.allow_to_push = true
        resource.protected = true
      end

      expect(protected_branch.name).to have_content(branch_name)
      expect(protected_branch.push_allowance).to have_content('Developers + Masters')
    end

    scenario 'users without authorization cannot push to protected branch' do
      Factory::Resource::Branch.fabricate! do |resource|
        resource.branch_name = branch_name
        resource.project = project
        resource.allow_to_push = false
        resource.protected = true
      end

      project.visit!

      Git::Repository.perform do |repository|
        repository.uri = location.uri
        repository.use_default_credentials

        repository.act do
          clone
          configure_identity('GitLab QA', 'root@gitlab.com')
          checkout('protected-branch')
          commit_file('README.md', 'readme content', 'Add a readme')
          push_changes('protected-branch')
        end

        expect(repository.push_error)
          .to match(/remote\: GitLab\: You are not allowed to push code to protected branches on this project/)
        expect(repository.push_error)
          .to match(/\[remote rejected\] #{branch_name} -> #{branch_name} \(pre-receive hook declined\)/)
      end
    end
  end
end

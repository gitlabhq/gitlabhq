module QA
  feature 'branch protection support', :core do
    given(:branch_name) { 'protected-branch' }
    given(:commit_message) { 'Protected push commit message' }
    given(:project) do
      Factory::Resource::Project.fabricate! do |resource|
        resource.name = 'protected-branch-project'
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
      let!(:protected_branch) { create_protected_branch(allow_to_push: true) }

      scenario 'user with push rights successfully pushes to the protected branch' do
        expect(protected_branch.name).to have_content(branch_name)
        expect(protected_branch.push_allowance).to have_content('Developers + Maintainers')

        push = push_new_file(branch_name)

        expect(push.output).to match(/remote: To create a merge request for protected-branch, visit/)
      end
    end

    context 'when developers and maintainers are not allowed to push to a protected branch' do
      scenario 'user without push rights fails to push to the protected branch' do
        create_protected_branch(allow_to_push: false)

        push = push_new_file(branch_name)

        expect(push.output)
          .to match(/remote\: GitLab\: You are not allowed to push code to protected branches on this project/)
        expect(push.output)
          .to match(/\[remote rejected\] #{branch_name} -> #{branch_name} \(pre-receive hook declined\)/)
      end
    end

    def create_protected_branch(allow_to_push:)
      Factory::Resource::Branch.fabricate! do |resource|
        resource.branch_name = branch_name
        resource.project = project
        resource.allow_to_push = allow_to_push
        resource.protected = true
      end
    end

    def push_new_file(branch)
      Factory::Repository::ProjectPush.fabricate! do |resource|
        resource.project = project
        resource.file_name = 'new_file.md'
        resource.file_content = '# This is a new file'
        resource.commit_message = 'Add new_file.md'
        resource.branch_name = branch_name
        resource.new_branch = false
      end
    end
  end
end

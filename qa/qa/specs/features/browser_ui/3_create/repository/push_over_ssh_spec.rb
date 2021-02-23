# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'SSH key support' do
      # Note: If you run these tests against GDK make sure you've enabled sshd
      # See: https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/run_qa_against_gdk.md

      let(:project) do
        Resource::Project.fabricate! do |project|
          project.name = 'ssh-tests'
        end
      end

      before(:context) do
        @key = Resource::SSHKey.fabricate_via_api! do |resource|
          resource.title = "key for ssh tests #{Time.now.to_f}"
        end
      end

      after(:context) do
        @key.remove_via_api!
      end

      before do
        Flow::Login.sign_in
      end

      it 'pushes code to the repository via SSH', :smoke, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1678' do
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.ssh_key = @key
          push.file_name = 'README.md'
          push.file_content = '# Test Use SSH Key'
          push.commit_message = 'Add README.md'
        end.project.visit!

        Page::Project::Show.perform do |project|
          expect(project).to have_file('README.md')
          expect(project).to have_readme_content('Test Use SSH Key')
        end
      end

      it 'pushes multiple branches and tags together', :smoke, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1679' do
        branches = []
        tags = []
        Git::Repository.perform do |repository|
          repository.uri = project.repository_ssh_location.uri
          repository.use_ssh_key(@key)
          repository.clone
          repository.configure_identity('GitLab QA', 'root@gitlab.com')
          1.upto(3) do |i|
            branches << "branch#{i}"
            tags << "tag#{i}"
            repository.checkout("branch#{i}", new_branch: true)
            repository.commit_file("file#{i}", SecureRandom.random_bytes(10000), "Add file#{i}")
            repository.add_tag("tag#{i}")
          end
          repository.push_tags_and_branches(branches)
        end

        expect(project).to have_branches(branches)
        expect(project).to have_tags(tags)
      end
    end
  end
end

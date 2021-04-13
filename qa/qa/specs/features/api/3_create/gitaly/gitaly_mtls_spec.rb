# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    context 'Gitaly', :orchestrated, :mtls do
      describe 'Using mTLS' do
        let(:intial_commit_message) { 'Initial commit' }
        let(:first_added_commit_message) { 'commit over git' }
        let(:second_added_commit_message) { 'commit over api' }

        it 'pushes to gitaly', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1118' do
          project = Resource::Project.fabricate! do |project|
            project.name = "mTLS"
            project.initialize_with_readme = true
          end

          Resource::Repository::ProjectPush.fabricate! do |push|
            push.project = project
            push.new_branch = false
            push.commit_message = first_added_commit_message
            push.file_content = 'First commit'
          end

          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.commit_message = second_added_commit_message
            commit.add_files([
              {
                file_path: "file-#{SecureRandom.hex(8)}",
                content: 'Second commit'
              }
            ])
          end

          expect(project.commits.map { |commit| commit[:message].chomp })
            .to include(intial_commit_message)
            .and include(first_added_commit_message)
            .and include(second_added_commit_message)
        end
      end
    end
  end
end

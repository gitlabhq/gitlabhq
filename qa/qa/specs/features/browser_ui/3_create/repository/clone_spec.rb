# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Git clone over HTTP', :smoke, product_group: :source_code do
      let(:project) { create(:project, name: 'project-with-code', description: 'project for git clone tests') }

      before do
        Git::Repository.perform do |repository|
          repository.uri = project.repository_http_location.uri
          repository.use_default_credentials
          repository.default_branch = project.default_branch

          repository.act do
            clone
            use_default_identity
            checkout(default_branch, new_branch: true)
            commit_file('test.rb', 'class Test; end', 'Add Test class')
            commit_file('README.md', '# Test', 'Add Readme')
            push_changes
          end
        end
        project.wait_for_push_new_branch
      end

      it 'user performs a deep clone', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347761' do
        Git::Repository.perform do |repository|
          repository.uri = project.repository_http_location.uri
          repository.use_default_credentials

          repository.clone

          expect(repository.commits.size).to eq(2), "Expected 2 commits, got: #{repository.commits.size}"
        end
      end

      it 'user performs a shallow clone', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347739' do
        Git::Repository.perform do |repository|
          repository.uri = project.repository_http_location.uri
          repository.use_default_credentials

          repository.shallow_clone

          expect(repository.commits.size).to eq(1), "Expected 1 commit, got: #{repository.commits.size}"
          expect(repository.commits.first).to include 'Add Readme'
        end
      end
    end
  end
end

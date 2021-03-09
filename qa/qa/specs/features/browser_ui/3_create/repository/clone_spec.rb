# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Git clone over HTTP' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |scenario|
          scenario.name = 'project-with-code'
          scenario.description = 'project for git clone tests'
        end
      end

      before do
        Git::Repository.perform do |repository|
          repository.uri = project.repository_http_location.uri
          repository.use_default_credentials
          repository.default_branch = project.default_branch

          repository.act do
            clone
            configure_identity('GitLab QA', 'root@gitlab.com')
            checkout(default_branch, new_branch: true)
            commit_file('test.rb', 'class Test; end', 'Add Test class')
            commit_file('README.md', '# Test', 'Add Readme')
            push_changes
          end
        end
        project.wait_for_push_new_branch
      end

      it 'user performs a deep clone', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/475' do
        Git::Repository.perform do |repository|
          repository.uri = project.repository_http_location.uri
          repository.use_default_credentials

          repository.clone

          expect(repository.commits.size).to eq 2
        end
      end

      it 'user performs a shallow clone', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/411' do
        Git::Repository.perform do |repository|
          repository.uri = project.repository_http_location.uri
          repository.use_default_credentials

          repository.shallow_clone

          expect(repository.commits.size).to eq 1
          expect(repository.commits.first).to include 'Add Readme'
        end
      end
    end
  end
end

# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Project access token' do
      before(:all) do
        @project_access_token = QA::Resource::ProjectAccessToken.fabricate_via_api!
        @user_api_client = Runtime::API::Client.new(:gitlab, personal_access_token: @project_access_token.token)
      end

      context 'for the same project' do
        it 'can be used to create a file via the project API', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1734' do
          expect do
            Resource::File.fabricate_via_api! do |file|
              file.api_client = @user_api_client
              file.project = @project_access_token.project
              file.branch = 'new_branch'
              file.commit_message = 'Add new file'
              file.name = "text-#{SecureRandom.hex(8)}.txt"
              file.content = 'New file'
            end
          end.not_to raise_error
        end

        it 'can be used to commit via the API', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1735' do
          expect do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              commit.api_client = @user_api_client
              commit.project = @project_access_token.project
              commit.branch = 'new_branch'
              commit.start_branch = @project_access_token.project.default_branch
              commit.commit_message = 'Add new file'
              commit.add_files([
                { file_path: "text-#{SecureRandom.hex(8)}.txt", content: 'new file' }
              ])
            end
          end.not_to raise_error
        end
      end

      context 'for a different project' do
        before(:all) do
          @different_project = Resource::Project.fabricate!
        end

        it 'cannot be used to create a file via the project API', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1736' do
          expect do
            Resource::File.fabricate_via_api! do |file|
              file.api_client = @user_api_client
              file.project = @different_project
              file.branch = 'new_branch'
              file.commit_message = 'Add new file'
              file.name = "text-#{SecureRandom.hex(8)}.txt"
              file.content = 'New file'
            end
          end.to raise_error(Resource::ApiFabricator::ResourceFabricationFailedError, /403 Forbidden/)
        end

        it 'cannot be used to commit via the API', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1737' do
          expect do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              commit.api_client = @user_api_client
              commit.project = @different_project
              commit.branch = 'new_branch'
              commit.start_branch = @different_project.default_branch
              commit.commit_message = 'Add new file'
              commit.add_files([
                { file_path: "text-#{SecureRandom.hex(8)}.txt", content: 'new file' }
              ])
            end
          end.to raise_error(Resource::ApiFabricator::ResourceFabricationFailedError, /403 Forbidden - You are not allowed to push into this branch/)
        end

        after(:all) do
          @different_project.remove_via_api!
        end
      end

      after(:all) do
        @project_access_token.remove_via_api!
        @project_access_token.project.remove_via_api!
      end
    end
  end
end

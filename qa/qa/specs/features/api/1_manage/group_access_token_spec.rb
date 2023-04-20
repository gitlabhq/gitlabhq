# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Group access token', product_group: :authentication_and_authorization do
      let(:group_access_token) { QA::Resource::GroupAccessToken.fabricate_via_api! }
      let(:api_client) { Runtime::API::Client.new(:gitlab, personal_access_token: group_access_token.token) }
      let(:project) do
        Resource::Project.fabricate! do |project|
          project.name = 'project-for-group-access-token'
          project.group = group_access_token.group
          project.initialize_with_readme = true
        end
      end

      it(
        'can be used to create a file via the project API',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/367064'
      ) do
        expect do
          Resource::File.fabricate_via_api! do |file|
            file.api_client = api_client
            file.project = project
            file.branch = "new_branch_#{SecureRandom.hex(8)}"
            file.commit_message = 'Add new file'
            file.name = "text-#{SecureRandom.hex(8)}.txt"
            file.content = 'New file'
          end
        rescue StandardError => e
          QA::Runtime::Logger.error("Full failure message: #{e.message}")
          raise
        end.not_to raise_error
      end

      it(
        'can be used to commit via the API',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/367067'
      ) do
        expect do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.api_client = api_client
            commit.project = project
            commit.branch = "new_branch_#{SecureRandom.hex(8)}"
            commit.start_branch = project.default_branch
            commit.commit_message = 'Add new file'
            commit.add_files([{ file_path: "text-#{SecureRandom.hex(8)}.txt", content: 'new file' }])
          end
        rescue StandardError => e
          QA::Runtime::Logger.error("Full failure message: #{e.message}")
          raise
        end.not_to raise_error
      end
    end
  end
end

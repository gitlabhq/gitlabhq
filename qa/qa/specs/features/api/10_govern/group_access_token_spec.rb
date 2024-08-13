# frozen_string_literal: true

module QA
  RSpec.describe 'Govern' do
    describe 'Group access token', product_group: :authentication do
      include QA::Support::Helpers::Project

      let(:group_access_token) { create(:group_access_token) }

      let(:api_client_with_group_token) do
        Runtime::API::Client.new(:gitlab, personal_access_token: group_access_token.token)
      end

      let(:project) do
        create(:project, name: 'project-for-group-access-token', group: group_access_token.group)
      end

      before do
        wait_until_project_is_ready(project)
        # Associating a group access token to a project requires a job to be processed in sidekiq
        # We need to be sure that this has happened or else we may get flaky test failures
        wait_until_token_associated_to_project(project, api_client_with_group_token)
      end

      it(
        'can be used to create a file via the project API', :smoke,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/367064'
      ) do
        expect do
          create(:file,
            api_client: api_client_with_group_token,
            project: project,
            branch: "new_branch_#{SecureRandom.hex(8)}")
        rescue StandardError => e
          QA::Runtime::Logger.error("Full failure message: #{e.message}")
          raise
        end.not_to raise_error
      end

      it(
        'can be used to commit via the API', :smoke,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/367067'
      ) do
        expect do
          create(:commit,
            api_client: api_client_with_group_token,
            project: project,
            branch: "new_branch_#{SecureRandom.hex(8)}",
            start_branch: project.default_branch,
            commit_message: 'Add new file', actions: [
              { action: 'create', file_path: "text-#{SecureRandom.hex(8)}.txt", content: 'new file' }
            ])
        rescue StandardError => e
          QA::Runtime::Logger.error("Full failure message: #{e.message}")
          raise
        end.not_to raise_error
      end
    end
  end
end

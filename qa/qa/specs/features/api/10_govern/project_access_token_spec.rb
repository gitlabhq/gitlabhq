# frozen_string_literal: true

module QA
  RSpec.describe 'Govern' do
    describe 'Project access token', product_group: :authentication do
      let!(:project) { create(:project, name: "project-to-test-project-access-token-#{SecureRandom.hex(4)}") }
      let!(:project_access_token) { create(:project_access_token, project: project) }
      let!(:user_api_client) { Runtime::API::Client.new(:gitlab, personal_access_token: project_access_token.token) }

      context 'for the same project' do
        it 'can be used to create a file via the project API',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347858' do
          expect do
            create(:file,
              api_client: user_api_client,
              project: project,
              branch: "new_branch_#{SecureRandom.hex(8)}")
          rescue StandardError => e
            QA::Runtime::Logger.error("Full failure message: #{e.message}")
            raise
          end.not_to raise_error
        end

        it 'can be used to commit via the API',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347859' do
          expect do
            create(:commit,
              api_client: user_api_client,
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

      context 'for a different project' do
        let(:different_project) do
          create(:project, name: "different-project-to-test-project-access-token-#{SecureRandom.hex(4)}")
        end

        after do
          different_project.remove_via_api!
        end

        it 'cannot be used to create a file via the project API',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347860' do
          expect do
            create(:file,
              api_client: user_api_client,
              project: different_project,
              branch: "new_branch_#{SecureRandom.hex(8)}")
          end.to raise_error(Resource::ApiFabricator::ResourceFabricationFailedError, /403 Forbidden/)
        end

        it 'cannot be used to commit via the API',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347861' do
          expect do
            create(:commit,
              api_client: user_api_client,
              project: different_project,
              branch: "new_branch_#{SecureRandom.hex(8)}",
              start_branch: different_project.default_branch,
              commit_message: 'Add new file', actions: [
                { action: 'create', file_path: "text-#{SecureRandom.hex(8)}.txt", content: 'new file' }
              ])
          end.to raise_error(Resource::ApiFabricator::ResourceFabricationFailedError,
            /403 Forbidden - You are not allowed to push into this branch/)
        end
      end
    end
  end
end

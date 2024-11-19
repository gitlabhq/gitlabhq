# frozen_string_literal: true

module QA
  RSpec.describe 'Govern' do
    describe 'Project access token', product_group: :authentication do
      include QA::Support::Helpers::Project

      let!(:project) { create(:project, name: "project-to-test-project-access-token") }
      let!(:project_access_token) { create(:project_access_token, project: project) }
      let!(:user_api_client) { Runtime::API::Client.new(:gitlab, personal_access_token: project_access_token.token) }

      before do
        wait_until_project_is_ready(project)
        # Associating an access token to a project requires a job to be processed in sidekiq
        # We need to be sure that this has happened or else we may get flaky test failures
        wait_until_token_associated_to_project(project, user_api_client)
      end

      context 'for the same project' do
        it 'can be used to create a file via the project API', :smoke,
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

        it 'can be used to commit via the API', :smoke,
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
          create(:project, name: "different-project-to-test-project-access-token")
        end

        before do
          wait_until_project_is_ready(different_project)
        end

        it 'cannot be used to create a file via the project API', :smoke,
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347860' do
          expect do
            create(:file,
              api_client: user_api_client,
              project: different_project,
              branch: "new_branch_#{SecureRandom.hex(8)}")
          end.to raise_error(Resource::ApiFabricator::ResourceFabricationFailedError, /403 Forbidden/)
        end

        it 'cannot be used to commit via the API', :smoke,
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

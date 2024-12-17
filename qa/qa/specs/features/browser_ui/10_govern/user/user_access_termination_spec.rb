# frozen_string_literal: true

module QA
  RSpec.describe 'Govern' do
    describe 'User', :requires_admin, :skip_live_env, product_group: :authentication do
      let!(:project) { create(:project, :with_readme, name: 'project-for-user-group-access-termination', group: group) }

      let(:user) { create(:user, :with_personal_access_token) }
      let(:user_api_client) { user.api_client }
      let(:sandbox) { create(:sandbox) }
      let(:group) { create(:group, sandbox: sandbox) }

      before do
        sandbox.add_member(user)
      end

      context 'when parent group membership is terminated' do
        before do
          sandbox.remove_member(user)
        end

        it 'is not allowed to push code via the CLI',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347863' do
          QA::Support::Retrier.retry_on_exception(max_attempts: 5, sleep_interval: 2) do
            expect do
              Resource::Repository::Push.fabricate! do |push|
                push.repository_http_uri = project.repository_http_location.uri
                push.file_name = 'test.txt'
                push.file_content = "# This is a test project named #{project.name}"
                push.commit_message = 'Add test.txt'
                push.branch_name = "new_branch_#{SecureRandom.hex(8)}"
                push.user = user
                push.max_attempts = 1
              end
            end.to raise_error(QA::Support::Run::CommandError, /You are not allowed to push code to this project/)
          end
        end

        it 'is not allowed to create a file via the API',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347864' do
          QA::Support::Retrier.retry_on_exception(max_attempts: 5, sleep_interval: 2) do
            expect do
              create(:file,
                api_client: user_api_client,
                project: project,
                branch: "new_branch_#{SecureRandom.hex(8)}")
            end.to raise_error(Resource::ApiFabricator::ResourceFabricationFailedError, /403 Forbidden/)
          end
        end

        it 'is not allowed to commit via the API',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347865' do
          QA::Support::Retrier.retry_on_exception(max_attempts: 5, sleep_interval: 2) do
            expect do
              create(:commit,
                api_client: user_api_client,
                project: project,
                branch: "new_branch_#{SecureRandom.hex(8)}",
                start_branch: project.default_branch,
                commit_message: 'Add new file',
                actions: [
                  { action: 'create', file_path: 'test.txt', content: 'new file' }
                ])
            end.to raise_error(Resource::ApiFabricator::ResourceFabricationFailedError,
              /403 Forbidden - You are not allowed to push into this branch/)
          end
        end
      end
    end
  end
end

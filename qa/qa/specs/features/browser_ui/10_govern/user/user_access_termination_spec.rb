# frozen_string_literal: true

module QA
  RSpec.describe 'Govern' do
    # TODO: `:reliable` should be added back once https://gitlab.com/gitlab-org/gitlab/-/issues/359278 is resolved
    describe 'User', :requires_admin, product_group: :authentication do
      # rubocop:disable RSpec/InstanceVariable
      before(:all) do
        admin_api_client = Runtime::API::Client.as_admin

        @user = create(:user, api_client: admin_api_client)

        @user_api_client = Runtime::API::Client.new(:gitlab, user: @user)

        # Use UI to create the top-level group as the `top_level_group_creation_enabled` feature flag
        # could be disabled on live environments
        @sandbox = Resource::Sandbox.fabricate! do |sandbox_group|
          sandbox_group.path = "sandbox-for-access-termination-#{SecureRandom.hex(4)}"
        end

        group = create(:group, path: "group-to-test-access-termination-#{SecureRandom.hex(8)}", sandbox: @sandbox)

        @sandbox.add_member(@user)

        @project = create(:project, :with_readme, name: 'project-for-user-group-access-termination', group: group)
      end

      after(:all) do
        @sandbox.remove_via_api!
      end

      context 'when parent group membership is terminated' do
        before do
          @sandbox.remove_member(@user)
        end

        it 'is not allowed to push code via the CLI',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347863' do
          QA::Support::Retrier.retry_on_exception(max_attempts: 5, sleep_interval: 2) do
            expect do
              Resource::Repository::Push.fabricate! do |push|
                push.repository_http_uri = @project.repository_http_location.uri
                push.file_name = 'test.txt'
                push.file_content = "# This is a test project named #{@project.name}"
                push.commit_message = 'Add test.txt'
                push.branch_name = "new_branch_#{SecureRandom.hex(8)}"
                push.user = @user
              end
            end.to raise_error(QA::Support::Run::CommandError, /You are not allowed to push code to this project/)
          end
        end

        it 'is not allowed to create a file via the API',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347864' do
          QA::Support::Retrier.retry_on_exception(max_attempts: 5, sleep_interval: 2) do
            expect do
              create(:file,
                api_client: @user_api_client,
                project: @project,
                branch: "new_branch_#{SecureRandom.hex(8)}")
            end.to raise_error(Resource::ApiFabricator::ResourceFabricationFailedError, /403 Forbidden/)
          end
        end

        it 'is not allowed to commit via the API',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347865' do
          QA::Support::Retrier.retry_on_exception(max_attempts: 5, sleep_interval: 2) do
            expect do
              create(:commit,
                api_client: @user_api_client,
                project: @project,
                branch: "new_branch_#{SecureRandom.hex(8)}",
                start_branch: @project.default_branch,
                commit_message: 'Add new file',
                actions: [
                  { action: 'create', file_path: 'test.txt', content: 'new file' }
                ])
            end.to raise_error(Resource::ApiFabricator::ResourceFabricationFailedError,
              /403 Forbidden - You are not allowed to push into this branch/)
          end
        end
      end
      # rubocop:enable RSpec/InstanceVariable
    end
  end
end

# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    # TODO: `:reliable` should be added back once https://gitlab.com/gitlab-org/gitlab/-/issues/359278 is resolved
    describe 'User', :requires_admin, product_group: :authentication_and_authorization do
      before(:all) do
        admin_api_client = Runtime::API::Client.as_admin

        @user = Resource::User.fabricate_via_api! do |user|
          user.api_client = admin_api_client
        end

        @user_api_client = Runtime::API::Client.new(:gitlab, user: @user)

        @sandbox = Resource::Sandbox.fabricate! do |sandbox_group|
          sandbox_group.path = "sandbox-for-access-termination-#{SecureRandom.hex(4)}"
          sandbox_group.api_client = admin_api_client
        end

        group = QA::Resource::Group.fabricate_via_api! do |group|
          group.path = "group-to-test-access-termination-#{SecureRandom.hex(8)}"
          group.sandbox = @sandbox
        end

        @sandbox.add_member(@user)

        @project = Resource::Project.fabricate_via_api! do |project|
          project.group = group
          project.name = "project-for-user-group-access-termination"
          project.initialize_with_readme = true
        end
      end

      context 'after parent group membership termination' do
        before do
          @sandbox.remove_member(@user)
        end

        it 'is not allowed to push code via the CLI', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347863' do
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

        it 'is not allowed to create a file via the API', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347864' do
          QA::Support::Retrier.retry_on_exception(max_attempts: 5, sleep_interval: 2) do
            expect do
              Resource::File.fabricate_via_api! do |file|
                file.api_client = @user_api_client
                file.project = @project
                file.branch = "new_branch_#{SecureRandom.hex(8)}"
                file.commit_message = 'Add new file'
                file.name = 'test.txt'
                file.content = "New file"
              end
            end.to raise_error(Resource::ApiFabricator::ResourceFabricationFailedError, /403 Forbidden/)
          end
        end

        it 'is not allowed to commit via the API', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347865' do
          QA::Support::Retrier.retry_on_exception(max_attempts: 5, sleep_interval: 2) do
            expect do
              Resource::Repository::Commit.fabricate_via_api! do |commit|
                commit.api_client = @user_api_client
                commit.project = @project
                commit.branch = "new_branch_#{SecureRandom.hex(8)}"
                commit.start_branch = @project.default_branch
                commit.commit_message = 'Add new file'
                commit.add_files([{ file_path: 'test.txt', content: 'new file' }])
              end
            end.to raise_error(Resource::ApiFabricator::ResourceFabricationFailedError, /403 Forbidden - You are not allowed to push into this branch/)
          end
        end
      end

      after(:all) do
        @sandbox.remove_via_api!
      end
    end
  end
end

# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'User', :requires_admin, product_group: :tenant_scale do
      let(:admin_api_client) { Runtime::API::Client.as_admin }

      let!(:parent_group) do
        QA::Resource::Group.fabricate_via_api! do |group|
          group.path = "parent-group-to-test-user-access-#{SecureRandom.hex(8)}"
        end
      end

      let!(:sub_group) do
        QA::Resource::Group.fabricate_via_api! do |group|
          group.path = "sub-group-to-test-user-access-#{SecureRandom.hex(8)}"
          group.sandbox = parent_group
        end
      end

      context 'when added to parent group' do
        let!(:parent_group_user) do
          Resource::User.fabricate_via_api! do |user|
            user.api_client = admin_api_client
          end
        end

        let!(:parent_group_user_api_client) do
          Runtime::API::Client.new(:gitlab, user: parent_group_user)
        end

        let!(:sub_group_project) do
          Resource::Project.fabricate_via_api! do |project|
            project.group = sub_group
            project.name = "sub-group-project-to-test-user-access"
            project.initialize_with_readme = true
          end
        end

        before do
          parent_group.add_member(parent_group_user)
        end

        after do
          parent_group_user.remove_via_api!
        end

        it(
          'is allowed to push code to sub-group project via the CLI',
          :reliable,
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/363345'
        ) do
          expect do
            Resource::Repository::Push.fabricate! do |push|
              push.repository_http_uri = sub_group_project.repository_http_location.uri
              push.file_name = 'test.txt'
              push.file_content = "# This is a test project named #{sub_group_project.name}"
              push.commit_message = 'Add test.txt'
              push.branch_name = "new_branch_#{SecureRandom.hex(8)}"
              push.user = parent_group_user
            end
          end.not_to raise_error
        end

        it(
          'is allowed to create a file in sub-group project via the API',
          :reliable,
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/363348'
        ) do
          expect do
            Resource::File.fabricate_via_api! do |file|
              file.api_client = parent_group_user_api_client
              file.project = sub_group_project
              file.branch = "new_branch_#{SecureRandom.hex(8)}"
              file.commit_message = 'Add new file'
              file.name = 'test.txt'
              file.content = "New file"
            end
          end.not_to raise_error
        end

        it(
          'is allowed to commit to sub-group project via the API',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/363349'
        ) do
          # Retry is needed due to delays with project authorization updates
          # Long term solution to accessing the status of a project authorization update
          # has been proposed in https://gitlab.com/gitlab-org/gitlab/-/issues/393369
          QA::Support::Retrier.retry_on_exception(max_attempts: 5, sleep_interval: 2) do
            expect do
              Resource::Repository::Commit.fabricate_via_api! do |commit|
                commit.api_client = parent_group_user_api_client
                commit.project = sub_group_project
                commit.branch = "new_branch_#{SecureRandom.hex(8)}"
                commit.start_branch = sub_group_project.default_branch
                commit.commit_message = 'Add new file'
                commit.add_files([{ file_path: 'test.txt', content: 'new file' }])
              end
            rescue StandardError => e
              QA::Runtime::Logger.error("Full failure message: #{e.message}")
              raise
            end.not_to raise_error
          end
        end
      end

      context 'when added to sub-group' do
        let!(:parent_group_project) do
          Resource::Project.fabricate_via_api! do |project|
            project.group = parent_group
            project.name = "parent-group-project-to-test-user-access"
            project.initialize_with_readme = true
          end
        end

        let!(:sub_group_user) do
          Resource::User.fabricate_via_api! do |user|
            user.api_client = admin_api_client
          end
        end

        let!(:sub_group_user_api_client) do
          Runtime::API::Client.new(:gitlab, user: sub_group_user)
        end

        before do
          sub_group.add_member(sub_group_user)
        end

        after do
          sub_group_user.remove_via_api!
        end

        it(
          'is not allowed to push code to parent group project via the CLI',
          :reliable,
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/363344'
        ) do
          expect do
            Resource::Repository::Push.fabricate! do |push|
              push.repository_http_uri = parent_group_project.repository_http_location.uri
              push.file_name = 'test.txt'
              push.file_content = "# This is a test project named #{parent_group_project.name}"
              push.commit_message = 'Add test.txt'
              push.branch_name = "new_branch_#{SecureRandom.hex(8)}"
              push.user = sub_group_user
            end
          end.to raise_error(QA::Support::Run::CommandError, /You are not allowed to push code to this project/)
        end

        it(
          'is not allowed to create a file in parent group project via the API',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/363343'
        ) do
          expect do
            Resource::File.fabricate_via_api! do |file|
              file.api_client = sub_group_user_api_client
              file.project = parent_group_project
              file.branch = "new_branch_#{SecureRandom.hex(8)}"
              file.commit_message = 'Add new file'
              file.name = 'test.txt'
              file.content = "New file"
            end
          end.to raise_error(Resource::ApiFabricator::ResourceFabricationFailedError, /403 Forbidden/)
        end

        it(
          'is not allowed to commit to parent group project via the API',
          :reliable,
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/363342'
        ) do
          expect do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              commit.api_client = sub_group_user_api_client
              commit.project = parent_group_project
              commit.branch = "new_branch_#{SecureRandom.hex(8)}"
              commit.start_branch = parent_group_project.default_branch
              commit.commit_message = 'Add new file'
              commit.add_files([{ file_path: 'test.txt', content: 'new file' }])
            end
          end.to raise_error(Resource::ApiFabricator::ResourceFabricationFailedError,
            /403 Forbidden - You are not allowed to push into this branch/)
        end
      end
    end
  end
end

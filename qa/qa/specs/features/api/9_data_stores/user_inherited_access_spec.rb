# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'User', :requires_admin, product_group: :tenant_scale do
      let!(:parent_group) { create(:group, path: "parent-group-to-test-user-access-#{SecureRandom.hex(8)}") }

      let!(:sub_group) do
        create(:group, path: "sub-group-to-test-user-access-#{SecureRandom.hex(8)}", sandbox: parent_group)
      end

      context 'when added to parent group' do
        include QA::Support::Helpers::Project

        let!(:parent_group_user) { create(:user, :with_personal_access_token) }
        let!(:parent_group_user_api_client) { parent_group_user.api_client }

        let!(:sub_group_project) do
          create(:project, :with_readme, name: 'sub-groupd-project-to-test-user-access', group: sub_group)
        end

        before do
          wait_until_project_is_ready(sub_group_project)

          parent_group.add_member(parent_group_user)
        end

        it(
          'is allowed to push code to sub-group project via the CLI',
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
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/363348'
        ) do
          # Retry is needed due to delays with project authorization updates
          # Long term solution to accessing the status of a project authorization update
          # has been proposed in https://gitlab.com/gitlab-org/gitlab/-/issues/393369
          QA::Support::Retrier.retry_on_exception(max_attempts: 30, sleep_interval: 2) do
            expect do
              create(:file,
                api_client: parent_group_user_api_client,
                project: sub_group_project,
                branch: "new_branch_#{SecureRandom.hex(8)}")
            end.not_to raise_error
          end
        end

        it(
          'is allowed to commit to sub-group project via the API',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/363349'
        ) do
          # Retry is needed due to delays with project authorization updates
          # Long term solution to accessing the status of a project authorization update
          # has been proposed in https://gitlab.com/gitlab-org/gitlab/-/issues/393369
          QA::Support::Retrier.retry_on_exception(max_attempts: 30, sleep_interval: 2) do
            expect do
              create(:commit,
                api_client: parent_group_user_api_client,
                project: sub_group_project,
                branch: "new_branch_#{SecureRandom.hex(8)}",
                start_branch: sub_group_project.default_branch,
                commit_message: 'Add new file', actions: [
                  { action: 'create', file_path: 'test.txt', content: 'new file' }
                ])
            rescue StandardError => e
              QA::Runtime::Logger.error("Full failure message: #{e.message}")
              raise
            end.not_to raise_error
          end
        end
      end

      context 'when added to sub-group' do
        let!(:parent_group_project) do
          create(:project, :with_readme, name: 'parent-group-project-to-test-user-access', group: parent_group)
        end

        let!(:sub_group_user) { create(:user, :with_personal_access_token) }
        let!(:sub_group_user_api_client) { sub_group_user.api_client }

        before do
          sub_group.add_member(sub_group_user)
        end

        it(
          'is not allowed to push code to parent group project via the CLI',
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
            create(:file,
              api_client: sub_group_user_api_client,
              project: parent_group_project,
              branch: "new_branch_#{SecureRandom.hex(8)}")
          end.to raise_error(Resource::ApiFabricator::ResourceFabricationFailedError, /403 Forbidden/)
        end

        it(
          'is not allowed to commit to parent group project via the API',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/363342'
        ) do
          expect do
            create(:commit,
              api_client: sub_group_user_api_client,
              project: parent_group_project,
              branch: "new_branch_#{SecureRandom.hex(8)}",
              start_branch: parent_group_project.default_branch,
              commit_message: 'Add new file', actions: [
                { action: 'create', file_path: 'test.txt', content: 'new file' }
              ])
          end.to raise_error(Resource::ApiFabricator::ResourceFabricationFailedError,
            /403 Forbidden - You are not allowed to push into this branch/)
        end
      end
    end
  end
end

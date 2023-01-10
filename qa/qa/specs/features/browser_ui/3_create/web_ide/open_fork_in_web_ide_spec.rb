# frozen_string_literal: true

module QA
  RSpec.describe 'Create', feature_flag: { name: 'vscode_web_ide', scope: :global }, product_group: :editor do
    describe 'Open a fork in Web IDE',
      skip: {
        issue: "https://gitlab.com/gitlab-org/gitlab/-/issues/351696",
        type: :flaky
      } do
      let(:parent_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'parent-project'
          project.initialize_with_readme = true
        end
      end

      before do
        Runtime::Feature.disable(:vscode_web_ide)
      end

      after do
        Runtime::Feature.enable(:vscode_web_ide)
      end

      context 'when a user does not have permissions to commit to the project' do
        let(:user) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2) }

        context 'when no fork is present' do
          it 'suggests to create a fork when a user clicks Web IDE in the main project', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347823' do
            Flow::Login.sign_in(as: user)

            parent_project.visit!
            Page::Project::Show.perform(&:open_web_ide!)

            Page::Project::WebIDE::Edit.perform(&:fork_project!)

            submit_merge_request_upstream
          end
        end

        context 'when a fork is already created' do
          let(:fork_project) do
            Resource::Fork.fabricate_via_api! do |fork|
              fork.user = user
              fork.upstream = parent_project
            end
          end

          it 'opens the fork when a user clicks Web IDE in the main project', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347824' do
            Flow::Login.sign_in(as: user)
            fork_project.upstream.visit!
            Page::Project::Show.perform do |project_page|
              expect(project_page).to have_edit_fork_button

              project_page.open_web_ide!
            end

            submit_merge_request_upstream
          end

          after do
            fork_project.project.remove_via_api!
          end
        end

        def submit_merge_request_upstream
          Page::Project::WebIDE::Edit.perform do |ide|
            ide.wait_until_ide_loads
            expect(ide).to have_project_path("#{user.username}/#{parent_project.name}")

            ide.add_file('new file', 'some random text')
            ide.commit_changes(open_merge_request: true)
          end

          Page::MergeRequest::New.perform(&:create_merge_request)

          parent_project.visit!
          Page::Project::Menu.perform(&:click_merge_requests)
          expect(page).to have_content('Update new file')
        end
      end
    end
  end
end

# frozen_string_literal: true

module QA
  # https://gitlab.com/gitlab-org/quality/staging/issues/39
  context 'Create', :quarantine do
    describe 'Codeowners' do
      it 'merge request assigns code owners as approvers' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        # Create one user to be the assigned approver and another user who will
        # not be an approver
        approver = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
        non_approver = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2)

        # Create a project and assign the users to it
        project = Resource::Project.fabricate! do |project|
          project.name = "assign-approvers"
        end
        project.visit!

        Page::Project::Menu.perform(&:go_to_members_settings)
        Page::Project::Settings::Members.perform do |members_page|
          members_page.add_member(approver.username)
          members_page.add_member(non_approver.username)
        end

        # Push CODEOWNERS to master
        project_push = Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.file_name = 'CODEOWNERS'
          push.file_content = <<~CONTENT
            CODEOWNERS @#{approver.username}
          CONTENT
          push.commit_message = 'Add CODEOWNERS and test files'
        end

        # Push a new CODEOWNERS file and create a merge request
        Resource::MergeRequest.fabricate! do |merge_request|
          merge_request.title = 'This is a merge request'
          merge_request.description = 'Change code owners'
          merge_request.project = project_push.project
          merge_request.file_name = 'CODEOWNERS'
          merge_request.file_content = <<~CONTENT
            CODEOWNERS @#{non_approver.username}
          CONTENT
        end

        # Check that the merge request assigns the original code owner as an
        # approver (because the current CODEOWNERS file in the master branch
        # doesn't have the new owner yet)
        Page::MergeRequest::Show.perform do |mr_page|
          mr_page.edit!
          expect(mr_page.approvers).to include(approver.name)
          expect(mr_page.approvers).not_to include(non_approver.name)
        end
      end
    end
  end
end

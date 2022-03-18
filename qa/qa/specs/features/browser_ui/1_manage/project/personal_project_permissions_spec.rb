# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Personal project permissions' do
      let!(:owner) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1) }

      let!(:owner_api_client) { Runtime::API::Client.new(:gitlab, user: owner) }

      let!(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.api_client = owner_api_client
          project.name = 'qa-owner-personal-project'
          project.personal_namespace = owner.username
        end
      end

      after do
        project&.remove_via_api!
      end

      context 'when user is added as Owner' do
        let(:issue) do
          Resource::Issue.fabricate_via_api! do |issue|
            issue.api_client = owner_api_client
            issue.project = project
            issue.title = 'Test Owner deletes issue'
          end
        end

        before do
          Flow::Login.sign_in(as: owner)
        end

        it "has Owner role with Owner permissions", testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352542' do
          Page::Dashboard::Projects.perform do |projects|
            projects.filter_by_name(project.name)

            expect(projects).to have_project_with_access_role(project.name, 'Owner')
          end

          expect_owner_permissions_allow_delete_issue
        end
      end

      context 'when user is added as Maintainer' do
        let(:maintainer) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2) }

        let(:issue) do
          Resource::Issue.fabricate_via_api! do |issue|
            issue.api_client = owner_api_client
            issue.project = project
            issue.title = 'Test Maintainer deletes issue'
          end
        end

        before do
          project.add_member(maintainer, Resource::Members::AccessLevel::MAINTAINER)
          Flow::Login.sign_in(as: maintainer)
        end

        it "has Maintainer role without Owner permissions", testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352607' do
          Page::Dashboard::Projects.perform do |projects|
            projects.filter_by_name(project.name)

            expect(projects).to have_project_with_access_role(project.name, 'Maintainer')
          end

          expect_maintainer_permissions_do_not_allow_delete_issue
        end
      end

      private

      def expect_owner_permissions_allow_delete_issue
        expect do
          issue.visit!

          Page::Project::Issue::Show.perform(&:delete_issue)

          Page::Project::Issue::Index.perform do |index|
            expect(index).not_to have_issue(issue)
          end
        end.not_to raise_error
      end

      def expect_maintainer_permissions_do_not_allow_delete_issue
        expect do
          issue.visit!

          Page::Project::Issue::Show.perform do |issue|
            expect(issue).not_to have_delete_issue_button
          end
        end.not_to raise_error
      end
    end
  end
end

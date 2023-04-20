# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'Project owner permissions', :reliable, product_group: :tenant_scale do
      let!(:owner) do
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
      end

      let!(:owner_api_client) { Runtime::API::Client.new(:gitlab, user: owner) }

      let!(:maintainer) do
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2)
      end

      shared_examples 'when user is added as owner' do |project_type, testcase|
        let!(:issue) do
          Resource::Issue.fabricate_via_api! do |issue|
            issue.api_client = owner_api_client
            issue.project = project
            issue.title = 'Test Owner Deletes Issue'
          end
        end

        before do
          project.add_member(owner, Resource::Members::AccessLevel::OWNER) if project_type == :group_project
          Flow::Login.sign_in(as: owner)
        end

        it "has owner role with owner permissions", testcase: testcase do
          Page::Dashboard::Projects.perform do |projects|
            projects.filter_by_name(project.name)

            expect(projects).to have_project_with_access_role(project.name, 'Owner')
          end

          issue.visit!

          Page::Project::Issue::Show.perform(&:delete_issue)

          Page::Project::Issue::Index.perform do |index|
            expect(index).not_to have_issue(issue)
          end
        end
      end

      shared_examples 'when user is added as maintainer' do |testcase|
        let!(:issue) do
          Resource::Issue.fabricate_via_api! do |issue|
            issue.api_client = owner_api_client
            issue.project = project
            issue.title = 'Test Maintainer Deletes Issue'
          end
        end

        before do
          project.add_member(maintainer, Resource::Members::AccessLevel::MAINTAINER)
          Flow::Login.sign_in(as: maintainer)
        end

        it "has maintainer role without owner permissions", testcase: testcase do
          Page::Dashboard::Projects.perform do |projects|
            projects.filter_by_name(project.name)

            expect(projects).to have_project_with_access_role(project.name, 'Maintainer')
          end

          issue.visit!

          Page::Project::Issue::Show.perform do |issue|
            expect(issue).not_to have_delete_issue_button
          end
        end
      end

      context 'for personal projects' do
        let!(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.api_client = owner_api_client
            project.name = 'qa-owner-personal-project'
            project.personal_namespace = owner.username
          end
        end

        it_behaves_like 'when user is added as owner', :personal_project, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352542'
        it_behaves_like 'when user is added as maintainer', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352607'
      end

      context 'for group projects' do
        let!(:group) { Resource::Group.fabricate_via_api! }

        let!(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.group = group
            project.name = 'qa-owner-group-project'
          end
        end

        it_behaves_like 'when user is added as owner', :group_project, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/366436'
        it_behaves_like 'when user is added as maintainer', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/366435'
      end
    end
  end
end

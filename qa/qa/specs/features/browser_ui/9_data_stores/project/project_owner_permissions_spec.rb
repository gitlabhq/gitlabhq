# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'Project owner permissions', :smoke, :requires_admin, product_group: :tenant_scale do
      let!(:owner) { Runtime::User::Store.test_user }
      let!(:owner_api_client) { owner.api_client }
      let!(:maintainer) { create(:user) }

      shared_examples 'adds user as owner' do |project_type, testcase|
        let!(:issue) do
          create(:issue, title: 'Test Owner Deletes Issue', project: project, api_client: owner_api_client)
        end

        before do
          project.add_member(owner, Resource::Members::AccessLevel::OWNER) if project_type == :group_project
          Flow::Login.sign_in(as: owner)
        end

        it "has owner role and permissions", testcase: testcase do
          Page::Dashboard::Projects.perform do |projects|
            projects.click_member_tab
            expect(projects).to have_filtered_project_with_access_role(project.name, 'Owner')
          end

          issue.visit!

          Page::Project::Issue::Show.perform(&:delete_issue)

          Page::Project::Issue::Index.perform do |index|
            expect(index).not_to have_issue(issue)
          end
        end
      end

      shared_examples 'adds user as maintainer' do |testcase|
        let!(:issue) do
          create(:issue, title: 'Test Maintainer Deletes Issue', project: project, api_client: owner_api_client)
        end

        before do
          project.add_member(maintainer, Resource::Members::AccessLevel::MAINTAINER)
          Flow::Login.sign_in(as: maintainer)
        end

        it "has maintainer role without owner permissions", testcase: testcase do
          Page::Dashboard::Projects.perform do |projects|
            projects.click_member_tab
            expect(projects).to have_filtered_project_with_access_role(project.name, 'Maintainer')
          end

          issue.visit!

          Page::Project::Issue::Show.perform do |issue|
            expect(issue).not_to have_delete_issue_button
          end
        end
      end

      context 'for personal projects' do
        let!(:project) { create(:project, name: 'qa-owner-personal-project', personal_namespace: owner.username) }

        it_behaves_like 'adds user as owner', :personal_project, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352542'
        it_behaves_like 'adds user as maintainer', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/352607'
      end

      context 'for group projects' do
        let!(:group) { create(:group) }
        let!(:project) { create(:project, name: 'qa-owner-group-project', group: group) }

        it_behaves_like 'adds user as owner', :group_project, 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/366436'
        it_behaves_like 'adds user as maintainer', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/366435'
      end
    end
  end
end

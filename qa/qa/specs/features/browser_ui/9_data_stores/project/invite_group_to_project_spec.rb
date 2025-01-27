# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'Invite group', product_group: :tenant_scale, quarantine: {
      type: :bug,
      issue: "https://gitlab.com/gitlab-org/gitlab/-/issues/436950",
      only: { pipeline: %i[canary production] }
    } do
      shared_examples 'invites group to project' do
        it 'grants group and members correct access level' do
          Page::Project::Menu.perform(&:go_to_members)
          Page::Project::Members.perform do |project_members|
            project_members.invite_group(group.path, 'Developer')

            expect(project_members).to have_group(group.path)
          end

          Flow::Login.sign_in(as: user)

          Page::Dashboard::Projects.perform do |projects|
            projects.click_member_tab
            expect(projects).to have_filtered_project_with_access_role(project.name, 'Developer')
          end

          project.visit!

          Page::Project::Show.perform do |project_page|
            expect(project_page).to have_name(project.name)
          end
        end
      end

      let(:user) { Runtime::User::Store.additional_test_user }

      before do
        Flow::Login.sign_in
        group.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
        project.visit!
      end

      context 'with a personal namespace project',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349223' do
        let(:group) { create(:group, path: "group-for-personal-project-#{SecureRandom.hex(8)}") }

        let(:project) do
          create(:project,
            :private,
            name: 'personal-namespace-project',
            description: 'test personal namespace project',
            personal_namespace: Runtime::User::Store.test_user.username)
        end

        it_behaves_like 'invites group to project'
      end

      context 'with a group project', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349340' do
        let(:group) { create(:group, path: "group-for-group-project-#{SecureRandom.hex(8)}") }
        let(:project) { create(:project, :private, name: 'group-project', description: 'test group project') }

        it_behaves_like 'invites group to project'
      end
    end
  end
end

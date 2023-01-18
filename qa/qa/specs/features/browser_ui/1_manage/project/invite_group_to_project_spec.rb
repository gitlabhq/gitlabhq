# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Invite group', :reliable, product_group: :organization do
      shared_examples 'invites group to project' do
        it 'verifies group is added and members can access project with correct access level' do
          Page::Project::Menu.perform(&:click_members)
          Page::Project::Members.perform do |project_members|
            project_members.invite_group(group.path, 'Developer')

            expect(project_members).to have_group(group.path)
          end

          Flow::Login.sign_in(as: user)

          Page::Dashboard::Projects.perform do |projects|
            projects.filter_by_name(project.name)

            expect(projects).to have_project_with_access_role(project.name, 'Developer')
          end

          project.visit!

          Page::Project::Show.perform do |project_page|
            expect(project_page).to have_name(project.name)
          end
        end
      end

      let(:user) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1) }

      before do
        Flow::Login.sign_in
        group.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
        project.visit!
      end

      context 'to personal namespace project', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349223' do
        let(:group) do
          Resource::Group.fabricate_via_api! do |group|
            group.path = "group-for-personal-project-#{SecureRandom.hex(8)}"
          end
        end

        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'personal-namespace-project'
            project.personal_namespace = Runtime::User.username
            project.visibility = :private
            project.description = 'test personal namespace project'
          end
        end

        it_behaves_like 'invites group to project'
      end

      context 'to group project', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349340' do
        let(:group) do
          Resource::Group.fabricate_via_api! do |group|
            group.path = "group-for-group-project-#{SecureRandom.hex(8)}"
          end
        end

        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'group-project'
            project.visibility = :private
            project.description = 'test group project'
          end
        end

        it_behaves_like 'invites group to project'
      end
    end
  end
end

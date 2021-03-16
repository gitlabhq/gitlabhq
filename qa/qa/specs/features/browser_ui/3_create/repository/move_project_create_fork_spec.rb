# frozen_string_literal: true

module QA
  RSpec.describe 'Create', :orchestrated, :repository_storage, :requires_admin do
    describe 'Gitaly repository storage' do
      let(:user) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1) }
      let(:parent_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'parent-project'
          project.initialize_with_readme = true
        end
      end

      let(:fork_project) do
        Resource::Fork.fabricate_via_api! do |fork|
          fork.user = user
          fork.upstream = parent_project
        end.project
      end

      before do
        Runtime::Feature.enable(:invite_members_group_modal, project: parent_project)
        parent_project.add_member(user)
      end

      it 'creates a 2nd fork after moving the parent project', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/713' do
        Flow::Login.sign_in(as: user)

        fork_project.visit!

        parent_project.change_repository_storage(QA::Runtime::Env.additional_repository_storage)

        second_fork_project = Resource::Fork.fabricate_via_api! do |fork|
          fork.name = "second-fork-of-#{parent_project.name}"
          fork.user = user
          fork.upstream = parent_project
        end.project

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = second_fork_project
          push.file_name = 'new_file'
          push.file_content = '# This is a new file'
          push.commit_message = 'Add new file'
          push.new_branch = false
        end.project.visit!

        Page::Project::Show.perform do |show|
          expect(show).to have_file('new_file')
          expect(show).to have_name(second_fork_project.name)
          expect(show).to be_forked_from(parent_project.name)
        end
      end
    end
  end
end

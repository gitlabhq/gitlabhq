# frozen_string_literal: true

module QA
  RSpec.describe 'Create', :orchestrated, :repository_storage, :requires_admin, product_group: :source_code do
    describe 'Gitaly repository storage' do
      let(:user) { create(:user, :with_personal_access_token) }
      let(:parent_project) { create(:project, :with_readme, name: 'parent-project') }
      let(:fork_project) { create(:fork, user: user, upstream: parent_project) }

      before do
        parent_project.add_member(user)
      end

      it 'creates a 2nd fork after moving the parent project',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347787',
        quarantine: {
          type: :flaky,
          issue: "https://gitlab.com/gitlab-org/gitlab/-/issues/456092"
        } do
        Flow::Login.sign_in(as: user)

        fork_project.visit!

        parent_project.change_repository_storage(QA::Runtime::Env.additional_repository_storage)

        second_fork_project = create(:fork,
          name: "second-fork-of-#{parent_project.name}",
          user: user,
          upstream: parent_project)

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = second_fork_project
          push.user = user
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

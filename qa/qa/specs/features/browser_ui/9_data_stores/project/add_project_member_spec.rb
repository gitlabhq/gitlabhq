# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores', :reliable, product_group: :tenant_scale do
    describe 'Project Member' do
      it 'adds a project member', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347887' do
        Flow::Login.sign_in

        user = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)

        project = create(:project, name: 'add-member-project')
        project.visit!

        Page::Project::Menu.perform(&:go_to_members)
        Page::Project::Members.perform do |members|
          members.add_member(user.username)
          members.search_member(user.username)
          expect(members).to have_content("@#{user.username}")
        end
      end
    end
  end
end

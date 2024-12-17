# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores', :smoke, product_group: :tenant_scale do
    describe 'Project Member' do
      it 'adds a project member', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347887' do
        Flow::Login.sign_in

        user = Runtime::User::Store.additional_test_user

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

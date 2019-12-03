# frozen_string_literal: true

module QA
  context 'Manage' do
    describe 'Add project member' do
      it 'user adds project member' do
        Flow::Login.sign_in

        user = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)

        project = Resource::Project.fabricate_via_api! do |resource|
          resource.name = 'add-member-project'
        end
        project.visit!

        Page::Project::Menu.perform(&:go_to_members_settings)
        Page::Project::Settings::Members.perform do |members|
          members.add_member(user.username)
        end

        expect(page).to have_content(/@#{user.username}(\n| )?Given access/)
      end
    end
  end
end

# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'User', :requires_admin, product_group: :tenant_scale do
      let!(:parent_group) do
        create(:group, path: "parent-group-to-test-user-access-#{SecureRandom.hex(8)}")
      end

      let!(:sub_group) do
        create(:group, path: "sub-group-to-test-user-access-#{SecureRandom.hex(8)}", sandbox: parent_group)
      end

      context 'when added to parent group' do
        let!(:parent_group_user) { create(:user, :with_personal_access_token) }
        let!(:parent_group_user_api_client) { parent_group_user.api_client }

        let!(:sub_group_project) do
          create(:project, :with_readme, name: 'sub-group-project-to-test-user-access', group: sub_group)
        end

        before do
          parent_group.add_member(parent_group_user)
        end

        it(
          'is allowed to edit the sub-group project files',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/363467'
        ) do
          Flow::Login.sign_in(as: parent_group_user)
          sub_group_project.visit!

          Page::Project::Show.perform do |project|
            project.click_file('README.md')
          end

          Page::File::Show.perform(&:click_edit)

          Page::File::Edit.perform do |file|
            file.click_commit_changes_in_header
            expect(file).to have_modal_commit_button
          end
        end
      end

      context 'when added to sub-group' do
        let!(:parent_group_project) do
          create(:project, :with_readme, name: 'parent-group-project-to-test-user-access', group: parent_group)
        end

        let!(:sub_group_user) { create(:user, :with_personal_access_token) }
        let!(:sub_group_user_api_client) { sub_group_user.api_client }

        before do
          sub_group.add_member(sub_group_user)
        end

        it(
          'is not allowed to edit the parent group project files',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/363466'
        ) do
          Flow::Login.sign_in(as: sub_group_user)
          parent_group_project.visit!

          Page::Project::Show.perform do |project|
            project.click_file('README.md')
          end

          Page::File::Show.perform(&:click_edit)

          expect(page).to have_text("You can’t edit files directly in this project.")
        end
      end
    end
  end
end

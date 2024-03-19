# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'User', :requires_admin, product_group: :tenant_scale do
      let(:admin_api_client) { Runtime::API::Client.as_admin }

      let!(:parent_group) do
        create(:group, path: "parent-group-to-test-user-access-#{SecureRandom.hex(8)}")
      end

      let!(:sub_group) do
        create(:group, path: "sub-group-to-test-user-access-#{SecureRandom.hex(8)}", sandbox: parent_group)
      end

      context 'when added to parent group' do
        let!(:parent_group_user) { create(:user, api_client: admin_api_client) }

        let!(:parent_group_user_api_client) do
          Runtime::API::Client.new(:gitlab, user: parent_group_user)
        end

        let!(:sub_group_project) do
          create(:project, :with_readme, name: 'sub-group-project-to-test-user-access', group: sub_group)
        end

        before do
          parent_group.add_member(parent_group_user)
        end

        after do
          parent_group_user.remove_via_api!
        end

        it(
          'is allowed to edit the sub-group project files', :reliable,
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/363467'
        ) do
          Flow::Login.sign_in(as: parent_group_user)
          sub_group_project.visit!

          Page::Project::Show.perform do |project|
            project.click_file('README.md')
          end

          Page::File::Show.perform(&:click_edit)

          Page::File::Form.perform do |file_form|
            expect(file_form).to have_element('data-testid': 'commit-button')
          end
        end
      end

      context 'when added to sub-group' do
        let!(:parent_group_project) do
          create(:project, :with_readme, name: 'parent-group-project-to-test-user-access', group: parent_group)
        end

        let!(:sub_group_user) { create(:user, api_client: admin_api_client) }

        let!(:sub_group_user_api_client) do
          Runtime::API::Client.new(:gitlab, user: sub_group_user)
        end

        before do
          sub_group.add_member(sub_group_user)
        end

        after do
          sub_group_user.remove_via_api!
        end

        it(
          'is not allowed to edit the parent group project files', :reliable,
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

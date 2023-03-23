# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'User', :requires_admin, product_group: :tenant_scale do
      let(:admin_api_client) { Runtime::API::Client.as_admin }

      let!(:parent_group) do
        QA::Resource::Group.fabricate_via_api! do |group|
          group.path = "parent-group-to-test-user-access-#{SecureRandom.hex(8)}"
        end
      end

      let!(:sub_group) do
        QA::Resource::Group.fabricate_via_api! do |group|
          group.path = "sub-group-to-test-user-access-#{SecureRandom.hex(8)}"
          group.sandbox = parent_group
        end
      end

      context 'when added to parent group' do
        let!(:parent_group_user) do
          Resource::User.fabricate_via_api! do |user|
            user.api_client = admin_api_client
          end
        end

        let!(:parent_group_user_api_client) do
          Runtime::API::Client.new(:gitlab, user: parent_group_user)
        end

        let!(:sub_group_project) do
          Resource::Project.fabricate_via_api! do |project|
            project.group = sub_group
            project.name = "sub-group-project-to-test-user-access"
            project.initialize_with_readme = true
          end
        end

        before do
          parent_group.add_member(parent_group_user)
        end

        after do
          parent_group_user.remove_via_api!
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

          Page::File::Form.perform do |file_form|
            expect(file_form).to have_element(:commit_button)
          end
        end
      end

      context 'when added to sub-group' do
        let!(:parent_group_project) do
          Resource::Project.fabricate_via_api! do |project|
            project.group = parent_group
            project.name = "parent-group-project-to-test-user-access"
            project.initialize_with_readme = true
          end
        end

        let!(:sub_group_user) do
          Resource::User.fabricate_via_api! do |user|
            user.api_client = admin_api_client
          end
        end

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

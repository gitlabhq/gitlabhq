# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'User', :requires_admin, :reliable, product_group: :tenant_scale do
      let(:admin_api_client) { Runtime::API::Client.as_admin }

      let!(:user) do
        Resource::User.fabricate_via_api! do |user|
          user.api_client = admin_api_client
        end
      end

      let!(:group) do
        QA::Resource::Group.fabricate_via_api! do |group|
          group.path = "group-to-test-access-termination-#{SecureRandom.hex(8)}"
        end
      end

      let!(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.group = group
          project.name = "project-for-user-access-termination"
          project.initialize_with_readme = true
        end
      end

      context 'when parent group membership is terminated' do
        before do
          group.add_member(user)

          Flow::Login.while_signed_in_as_admin do
            group.visit!

            Page::Group::Menu.perform(&:click_subgroup_members_item)
            Page::Group::Members.perform do |members_page|
              members_page.search_member(user.username)
              members_page.remove_member(user.username)
            end
          end
        end

        it 'is not allowed to edit the project files',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347866' do
          Flow::Login.sign_in(as: user)
          project.visit!

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

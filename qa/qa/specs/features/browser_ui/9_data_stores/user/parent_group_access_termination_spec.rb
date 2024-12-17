# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'User', :requires_admin, product_group: :tenant_scale do
      let(:admin_api_client) { Runtime::API::Client.as_admin }

      let!(:user) { create(:user, api_client: admin_api_client) }

      let!(:group) { create(:group, path: "group-to-test-access-termination-#{SecureRandom.hex(8)}") }

      let!(:project) { create(:project, :with_readme, name: 'project-for-user-access-termination', group: group) }

      context 'with terminated parent group membership' do
        before do
          group.add_member(user)

          Flow::Login.while_signed_in_as_admin do
            group.visit!

            Page::Group::Menu.perform(&:go_to_members)
            Page::Group::Members.perform do |members_page|
              members_page.search_member(user.username)
              members_page.remove_member(user.username)
            end
          end
        end

        it 'can not edit the project files',
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

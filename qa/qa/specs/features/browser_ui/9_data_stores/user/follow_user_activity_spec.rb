# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'User', :requires_admin, product_group: :tenant_scale do
      let(:admin_api_client) { Runtime::API::Client.as_admin }

      let(:followed_user_api_client) { Runtime::API::Client.new(:gitlab, user: followed_user) }

      let(:followed_user) { create(:user, name: "followed_user_#{SecureRandom.hex(8)}", api_client: admin_api_client) }

      let(:following_user) do
        create(:user, name: "following_user_#{SecureRandom.hex(8)}", api_client: admin_api_client)
      end

      let(:group) do
        group = create(:group,
          path: "group_for_follow_user_activity_#{SecureRandom.hex(8)}",
          api_client: admin_api_client)
        group.add_member(followed_user, Resource::Members::AccessLevel::MAINTAINER)
        group
      end

      let(:project) do
        create(:project, :with_readme, name: 'project-for-tags', api_client: followed_user_api_client, group: group)
      end

      let(:merge_request) { create(:merge_request, project: project, api_client: followed_user_api_client) }

      let(:issue) { create(:issue, project: project, api_client: followed_user_api_client) }

      let(:comment) do
        create(:issue_note,
          project: project,
          issue: issue,
          body: 'This is a comment',
          api_client: followed_user_api_client)
      end

      before do
        # Create both tokens before logging in the first time so that we don't need to log out in the middle of the test
        admin_api_client.personal_access_token
        followed_user_api_client.personal_access_token
      end

      after do
        project&.api_client = admin_api_client
        project&.remove_via_api!
        followed_user&.remove_via_api!
        following_user&.remove_via_api!
      end

      it 'can be followed and their activity seen', :reliable,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347678' do
        Flow::Login.sign_in(as: following_user)
        page.visit Runtime::Scenario.gitlab_address + "/#{followed_user.username}"
        Page::User::Show.perform(&:click_follow_user_link)

        expect(page).to have_text("No activities found")

        project
        merge_request
        issue
        comment

        Page::Main::Menu.perform(&:click_user_profile_link)
        Page::User::Show.perform do |show|
          show.click_following_tab
          show.click_user_link(followed_user.username)

          aggregate_failures do
            expect(show).to have_activity('created project')
            expect(show).to have_activity('opened merge request')
            expect(show).to have_activity('opened issue')
            expect(show).to have_activity('commented on issue')
          end
        end
      end
    end
  end
end

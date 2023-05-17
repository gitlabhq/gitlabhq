# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'User', :requires_admin, product_group: :tenant_scale do
      let(:admin_api_client) { Runtime::API::Client.as_admin }

      let(:followed_user_api_client) { Runtime::API::Client.new(:gitlab, user: followed_user) }

      let(:followed_user) do
        Resource::User.fabricate_via_api! do |user|
          user.name = "followed_user_#{SecureRandom.hex(8)}"
          user.api_client = admin_api_client
        end
      end

      let(:following_user) do
        Resource::User.fabricate_via_api! do |user|
          user.name = "following_user_#{SecureRandom.hex(8)}"
          user.api_client = admin_api_client
        end
      end

      let(:group) do
        group = QA::Resource::Group.fabricate_via_api! do |group|
          group.path = "group_for_follow_user_activity_#{SecureRandom.hex(8)}"
          group.api_client = admin_api_client
        end
        group.add_member(followed_user, Resource::Members::AccessLevel::MAINTAINER)
        group
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-for-tags'
          project.initialize_with_readme = true
          project.api_client = followed_user_api_client
          project.group = group
        end
      end

      let(:merge_request) do
        Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.project = project
          mr.api_client = followed_user_api_client
        end
      end

      let(:issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
          issue.api_client = followed_user_api_client
        end
      end

      let(:comment) do
        Resource::ProjectIssueNote.fabricate_via_api! do |project_issue_note|
          project_issue_note.project = project
          project_issue_note.issue = issue
          project_issue_note.body = 'This is a comment'
          project_issue_note.api_client = followed_user_api_client
        end
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

      it 'can be followed and their activity seen',
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

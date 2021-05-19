# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'User', :requires_admin do
      let(:admin_api_client) { Runtime::API::Client.as_admin }

      let(:user) do
        Resource::User.fabricate_via_api! do |user|
          user.api_client = admin_api_client
        end
      end

      let(:user_api_client) do
        Runtime::API::Client.new(:gitlab, user: user)
      end

      let(:group) do
        group = QA::Resource::Group.fabricate_via_api! do |group|
          group.path = "group_for_follow_user_activity_#{SecureRandom.hex(8)}"
        end
        group.add_member(user)
        group
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-for-tags'
          project.initialize_with_readme = true
          project.api_client = user_api_client
          project.group = group
        end
      end

      let(:merge_request) do
        Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.project = project
          mr.api_client = user_api_client
        end
      end

      let(:issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
          issue.api_client = user_api_client
        end
      end

      let(:comment) do
        Resource::ProjectIssueNote.fabricate_via_api! do |project_issue_note|
          project_issue_note.project = project
          project_issue_note.issue = issue
          project_issue_note.body = 'This is a comment'
          project_issue_note.api_client = user_api_client
        end
      end

      before do
        # Create both tokens before logging in the first time so that we don't need to log out in the middle of the test
        admin_api_client.personal_access_token
        user_api_client.personal_access_token
      end

      it 'can be followed and their activity seen', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1773' do
        Flow::Login.sign_in
        page.visit Runtime::Scenario.gitlab_address + "/#{user.username}"
        Page::User::Show.perform(&:click_follow_user_link)

        expect(page).to have_text("No activities found")

        project
        merge_request
        issue
        comment

        Page::Main::Menu.perform(&:click_user_profile_link)
        Page::User::Show.perform do |show|
          show.click_following_link
          show.click_user_link(user.username)

          aggregate_failures do
            expect(show).to have_activity('created project')
            expect(show).to have_activity('opened merge request')
            expect(show).to have_activity('opened issue')
            expect(show).to have_activity('commented on issue')
          end
        end
      end

      after do
        project.api_client = admin_api_client
        project.remove_via_api!
        user.remove_via_api!
      end
    end
  end
end

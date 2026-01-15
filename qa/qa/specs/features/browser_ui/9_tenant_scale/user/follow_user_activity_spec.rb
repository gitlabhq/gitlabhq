# frozen_string_literal: true

module QA
  RSpec.describe 'Tenant Scale', feature_category: :organization do
    describe 'User', :requires_admin do
      let(:admin_api_client) { Runtime::User::Store.admin_api_client }
      let(:followed_user_api_client) { followed_user.api_client }

      let(:followed_user) do
        create(:user, :with_personal_access_token, name: "QA User followed_user_#{SecureRandom.hex(8)}")
      end

      let(:following_user) do
        create(:user, :with_personal_access_token, name: "QA User following_user_#{SecureRandom.hex(8)}")
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

        # Waits added to reduce flakiness caused by async activity propagation and intermittent UI timing.
        # See: https://gitlab.com/gitlab-org/quality/test-failure-issues/-/work_items/12639
        # Activity feed updates asynchronously. Reload between attempts until the expected event appears.
        QA::Support::Waiter.wait_until(
          max_duration: 120,
          sleep_interval: 3,
          reload_page: page,
          message: "Timed out waiting for 'commented on issue' activity to appear"
        ) do
          Page::User::Show.perform { |show| show.has_activity?('commented on issue') }
        end

        QA::Support::Waiter.wait_until(
          max_duration: 60,
          sleep_interval: 2,
          reload_page: false,
          message: 'Failed to navigate to followed user via Following tab'
        ) do
          Page::Main::Menu.perform(&:click_user_profile_link)

          Page::User::Show.perform do |show|
            show.click_following_tab
            show.click_user_link(followed_user.username)

            show.has_activity?('commented on issue')
          end
        rescue Capybara::ElementNotFound, Selenium::WebDriver::Error::StaleElementReferenceError => e
          QA::Runtime::Logger.debug("Follow user activity navigation retry: #{e.class} - #{e.message}")
          page.visit Runtime::Scenario.gitlab_address + "/#{followed_user.username}"
          false
        end

        Page::User::Show.perform do |show|
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

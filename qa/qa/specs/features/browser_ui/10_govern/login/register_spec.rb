# frozen_string_literal: true

module QA
  RSpec.describe 'Govern', :skip_signup_disabled, :requires_admin, product_group: :authentication do
    describe 'while LDAP is enabled', :orchestrated, :ldap_no_tls,
      testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347934' do
      it 'allows the user to register and login' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        ldap_user = Runtime::User::Store.ldap_user
        Resource::User.fabricate_via_browser_ui! do |user|
          user.username = ldap_user.username
          user.password = ldap_user.password
          user.email_domain = 'gitlab.com'
          user.ldap_user = true
        end

        Page::Main::Menu.perform do |menu|
          expect(menu).to have_personal_area
        end
      end
    end

    # TODO: needs to be refactored to correctly support parallel testing
    # If any other spec file depends on require_admin_approval setting, it could fail
    describe 'standard', :smoke, :external_api_calls do
      context 'when admin approval is not required' do
        around do |example|
          with_application_settings(require_admin_approval_after_user_signup: false) { example.run }
        end

        context "with basic registration",
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347867' do
          it 'allows the user to register and login' do
            Runtime::Browser.visit(:gitlab, Page::Main::Login)

            Resource::User.fabricate_via_browser_ui! do |user_resource|
              user_resource.email_domain = 'gitlab.com'
            end

            Page::Main::Menu.perform do |menu|
              expect(menu).to have_personal_area
            end
          end
        end

        context "with user deletion" do
          let(:user) { create(:user) }

          it "allows to delete user account",
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/500258' do
            Flow::Login.sign_in(as: user)
            Page::Main::Menu.perform(&:click_edit_profile_link)
            Page::Profile::Menu.perform(&:click_account)
            Page::Profile::Accounts::Show.perform do |show|
              show.delete_account(user.password)
            end

            expect { user.exists? }.to eventually_be_falsey.within(max_duration: 120, sleep_interval: 3),
              "Expected user to be deleted, but it still exists"
          end

          it "allows to recreate deleted user with same credeintials",
            quarantine: {
              issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/500942',
              type: :investigating
            },
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/500257' do
            user.remove_via_api!
            # make sure user is deleted
            Support::Waiter.wait_until(max_duration: 120, sleep_interval: 3) { !user.exists? }

            Flow::Login.sign_in(as: user, skip_page_validation: true)
            expect(page).to have_text("Invalid login or password")

            Resource::User.fabricate_via_browser_ui! do |resource|
              resource.name = user.name
              resource.username = user.username
              resource.email = user.email
            end
            expect(Page::Main::Menu.perform(&:signed_in?)).to be_truthy, "Expected user to be recreated successfully"
          end
        end
      end

      context 'when admin approval is required', :external_api_calls,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347871' do
        let(:signed_up_waiting_approval_text) do
          'You have signed up successfully. However, we could not sign you in because your account ' \
            'is awaiting approval from your GitLab administrator.'
        end

        let(:pending_approval_blocked_text) do
          'Your account is pending approval from your GitLab administrator and hence blocked. ' \
            'Please contact your GitLab administrator if you think this is an error.'
        end

        let(:user) do
          Resource::User.fabricate_via_browser_ui! do |user|
            user.email_domain = 'gitlab.com'
            user.expect_fabrication_success = false
          end
        end

        around do |example|
          with_application_settings(require_admin_approval_after_user_signup: true) { example.run }
        end

        it 'allows user login after approval' do
          user # sign up user

          expect(page).to have_text(signed_up_waiting_approval_text)

          Flow::Login.sign_in(as: user, skip_page_validation: true)

          expect(page).to have_text(pending_approval_blocked_text)

          approve_user(user)

          Flow::Login.sign_in(as: user, skip_page_validation: true)

          Flow::UserOnboarding.onboard_user
          # In development env and .com the user is asked to create a group and a project
          Flow::UserOnboarding.create_initial_project if page.has_text?("Create or import your first project", wait: 0)
          Runtime::Browser.visit(:gitlab, Page::Dashboard::Welcome)

          expect(Page::Main::Menu.perform(&:has_personal_area?)).to be_truthy
        end
      end
    end

    def approve_user(user)
      Flow::Login.while_signed_in_as_admin do
        Page::Main::Menu.perform(&:go_to_admin_area)
        Page::Admin::Menu.perform(&:go_to_users_overview)
        Page::Admin::Overview::Users::Index.perform do |index|
          index.choose_pending_approval_filter
          index.choose_search_user(user.username)
          index.click_search
          index.click_user(user.name)
        end

        Page::Admin::Overview::Users::Show.perform do |show|
          user.id = show.user_id.to_i
          show.approve_user(user)
        end

        expect(page).to have_text('Successfully approved')
      end
    end

    def with_application_settings(**hargs)
      Runtime::ApplicationSettings.set_application_settings(**hargs)
      yield
    ensure
      Runtime::ApplicationSettings.restore_application_settings(*hargs.keys)
    end
  end
end

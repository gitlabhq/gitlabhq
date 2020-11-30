# frozen_string_literal: true

module QA
  module Flow
    module SignUp
      module_function

      def sign_up!(user)
        Page::Main::Login.perform(&:switch_to_register_page)

        success = Support::Retrier.retry_until(raise_on_failure: false) do
          Page::Registration::SignUp.perform do |sign_up|
            sign_up.fill_new_user_first_name_field(user.first_name)
            sign_up.fill_new_user_last_name_field(user.last_name)
            sign_up.fill_new_user_username_field(user.username)
            sign_up.fill_new_user_email_field(user.email)
            sign_up.fill_new_user_password_field(user.password)
            sign_up.click_new_user_register_button
          end

          # Because invisible_captcha would prevent submitting this form
          # within 4 seconds, sleep here. This can be removed once we
          # implement invisible_captcha as an application setting instead
          # of a feature flag, so we can turn it off while testing.
          # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/284113
          sleep 4

          Page::Registration::Welcome.perform(&:click_get_started_button_if_available)

          if user.expect_fabrication_success
            Page::Main::Menu.perform(&:has_personal_area?)
          else
            Page::Main::Menu.perform(&:not_signed_in?)
          end
        end

        raise "Failed to register the user" unless success
      end
    end
  end
end

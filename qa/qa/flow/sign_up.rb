# frozen_string_literal: true

module QA
  module Flow
    module SignUp
      module_function

      def sign_up!(user)
        Page::Main::Menu.perform(&:sign_out_if_signed_in)
        Page::Main::Login.perform(&:switch_to_register_page)
        Page::Registration::SignUp.perform do |sign_up|
          sign_up.fill_new_user_first_name_field(user.first_name)
          sign_up.fill_new_user_last_name_field(user.last_name)
          sign_up.fill_new_user_username_field(user.username)
          sign_up.fill_new_user_email_field(user.email)
          sign_up.fill_new_user_password_field(user.password)

          # Because invisible_captcha would prevent submitting this form
          # within 4 seconds, sleep here. This can be removed once we
          # implement invisible_captcha as an application setting instead
          # of a feature flag, so we can turn it off while testing.
          # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/284113
          sleep 5

          sign_up.click_new_user_register_button
        end

        Page::Registration::Welcome.perform(&:click_get_started_button_if_available)

        success = if user.expect_fabrication_success
                    Page::Main::Menu.perform(&:has_personal_area?)
                  else
                    Page::Main::Menu.perform(&:not_signed_in?)
                  end

        raise "Failed user registration attempt. Registration was expected to #{user.expect_fabrication_success ? 'succeed' : 'fail'} but #{success ? 'succeeded' : 'failed'}." unless success
      end

      def disable_sign_ups
        Flow::Login.sign_in_as_admin
        Page::Main::Menu.perform(&:go_to_admin_area)
        Page::Admin::Menu.perform(&:go_to_general_settings)

        Page::Admin::Settings::General.perform do |general_settings|
          general_settings.expand_sign_up_restrictions do |signup_settings|
            signup_settings.disable_signups
            signup_settings.save_changes
          end
        end
      end
    end
  end
end

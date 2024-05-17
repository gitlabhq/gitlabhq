# frozen_string_literal: true

module QA
  module Flow
    module SignUp
      extend self

      def page
        Capybara.current_session
      end

      def sign_up!(user)
        Page::Main::Menu.perform(&:sign_out_if_signed_in)
        Page::Main::Login.perform(&:switch_to_register_page)
        Page::Registration::SignUp.perform do |sign_up|
          sign_up.register_user(user)
        end

        Flow::UserOnboarding.onboard_user

        success = if user.expect_fabrication_success
                    # In development env and .com the user is asked to create a group and a project which can be skipped for
                    # the purpose of signing up
                    Runtime::Browser.visit(:gitlab, Page::Dashboard::Welcome)
                    Page::Main::Menu.perform(&:has_personal_area?)
                  else
                    Page::Main::Menu.perform(&:not_signed_in?)
                  end

        return if success

        raise "Failed user registration attempt. Registration was expected to #{user.expect_fabrication_success ? 'succeed' : 'fail'} but #{success ? 'succeeded' : 'failed'}."
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

QA::Flow::SignUp.prepend_mod_with('Flow::SignUp', namespace: QA)

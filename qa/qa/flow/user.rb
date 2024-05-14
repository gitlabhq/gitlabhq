# frozen_string_literal: true

module QA
  module Flow
    module User
      extend self

      def page
        Capybara.current_session
      end

      def confirm_user(user)
        Flow::Login.while_signed_in_as_admin do
          Page::Main::Menu.perform(&:go_to_admin_area)
          Page::Admin::Menu.perform(&:go_to_users_overview)
          Page::Admin::Overview::Users::Index.perform do |index|
            index.choose_search_user(user.email)
            index.click_search
            index.click_user(user.name)
          end

          Page::Admin::Overview::Users::Show.perform(&:confirm_user)
        end
      end
    end
  end
end

QA::Flow::User.prepend_mod_with('Flow::User', namespace: QA)

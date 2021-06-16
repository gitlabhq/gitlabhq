# frozen_string_literal: true

module QA
  module Flow
    module User
      module_function

      def page
        Capybara.current_session
      end

      def confirm_user(user)
        Flow::Login.while_signed_in_as_admin do
          Page::Main::Menu.perform(&:go_to_admin_area)
          Page::Admin::Menu.perform(&:go_to_users_overview)
          Page::Admin::Overview::Users::Index.perform do |index|
            index.search_user(user.email)
            index.click_user(user.name)
          end

          Page::Admin::Overview::Users::Show.perform(&:confirm_user)
        end
      end
    end
  end
end

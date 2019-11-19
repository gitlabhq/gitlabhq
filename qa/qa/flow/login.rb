# frozen_string_literal: true

module QA
  module Flow
    module Login
      module_function

      def while_signed_in(as: nil)
        Page::Main::Menu.perform(&:sign_out_if_signed_in)

        sign_in(as: as)

        yield

        Page::Main::Menu.perform(&:sign_out)
      end

      def while_signed_in_as_admin
        while_signed_in(as: Runtime::User.admin) do
          yield
        end
      end

      def sign_in(as: nil)
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform { |login| login.sign_in_using_credentials(user: as) }
      end

      def sign_in_as_admin
        sign_in(as: Runtime::User.admin)
      end

      def sign_in_unless_signed_in(as: nil)
        sign_in(as: as) unless Page::Main::Menu.perform(&:signed_in?)
      end
    end
  end
end

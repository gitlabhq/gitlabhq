# frozen_string_literal: true

module QA
  module Flow
    module Login
      module_function

      def while_signed_in(as: nil, address: :gitlab)
        Page::Main::Menu.perform(&:sign_out_if_signed_in)

        sign_in(as: as, address: address)

        yield

        Page::Main::Menu.perform(&:sign_out)
      end

      def while_signed_in_as_admin(address: :gitlab)
        while_signed_in(as: Runtime::User.admin, address: address) do
          yield
        end
      end

      def sign_in(as: nil, address: :gitlab)
        Runtime::Browser.visit(address, Page::Main::Login)
        Page::Main::Login.perform { |login| login.sign_in_using_credentials(user: as) }
      end

      def sign_in_as_admin(address: :gitlab)
        sign_in(as: Runtime::User.admin, address: address)
      end

      def sign_in_unless_signed_in(as: nil, address: :gitlab)
        sign_in(as: as, address: address) unless Page::Main::Menu.perform(&:signed_in?)
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Page
    module Main
      module Login
        # @note Defined as +text_field :login_field+
        # @return [String] The text content or value of +login_field+
        def login_field
          # This is a stub, used for indexing. The method is dynamically generated.
        end

        # Set the value of login_field
        # @example
        #   Gitlab::Page::Main::Login.perform do |login|
        #     login.login_field = 'value'
        #   end
        # @param value [String] The value to set.
        def login_field=(value)
          # This is a stub, used for indexing. The method is dynamically generated.
        end

        # @example
        #   Gitlab::Page::Main::Login.perform do |login|
        #     expect(login.login_field_element).to exist
        #   end
        # @return [Watir::TextField] The raw +TextField+ element
        def login_field_element
          # This is a stub, used for indexing. The method is dynamically generated.
        end

        # @example
        #   Gitlab::Page::Main::Login.perform do |login|
        #     expect(login).to be_login_field
        #   end
        # @return [Boolean] true if the +login_field+ element is present on the page
        def login_field?
          # This is a stub, used for indexing. The method is dynamically generated.
        end

        # @note Defined as +text_field :password_field+
        # @return [String] The text content or value of +password_field+
        def password_field
          # This is a stub, used for indexing. The method is dynamically generated.
        end

        # Set the value of password_field
        # @example
        #   Gitlab::Page::Main::Login.perform do |login|
        #     login.password_field = 'value'
        #   end
        # @param value [String] The value to set.
        def password_field=(value)
          # This is a stub, used for indexing. The method is dynamically generated.
        end

        # @example
        #   Gitlab::Page::Main::Login.perform do |login|
        #     expect(login.password_field_element).to exist
        #   end
        # @return [Watir::TextField] The raw +TextField+ element
        def password_field_element
          # This is a stub, used for indexing. The method is dynamically generated.
        end

        # @example
        #   Gitlab::Page::Main::Login.perform do |login|
        #     expect(login).to be_password_field
        #   end
        # @return [Boolean] true if the +password_field+ element is present on the page
        def password_field?
          # This is a stub, used for indexing. The method is dynamically generated.
        end

        # @note Defined as +button :sign_in_button+
        # Clicks +sign_in_button+
        def sign_in_button
          # This is a stub, used for indexing. The method is dynamically generated.
        end

        # @example
        #   Gitlab::Page::Main::Login.perform do |login|
        #     expect(login.sign_in_button_element).to exist
        #   end
        # @return [Watir::Button] The raw +Button+ element
        def sign_in_button_element
          # This is a stub, used for indexing. The method is dynamically generated.
        end

        # @example
        #   Gitlab::Page::Main::Login.perform do |login|
        #     expect(login).to be_sign_in_button
        #   end
        # @return [Boolean] true if the +sign_in_button+ element is present on the page
        def sign_in_button?
          # This is a stub, used for indexing. The method is dynamically generated.
        end
      end
    end
  end
end

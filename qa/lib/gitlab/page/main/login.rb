# frozen_string_literal: true

module Gitlab
  module Page
    module Main
      class Login < Chemlab::Page
        path '/users/sign_in'

        text_field :login_field
        text_field :password_field
        button :sign_in_button

        button :accept_terms, text: 'Accept terms'

        # password change tab
        text_field :password_confirmation_field
        button :change_password_button

        # Sign in using a given username and password
        # @note this will also automatically accept terms if prompted
        # @param [String] username the username to sign in with
        # @param [String] password the password to sign in with
        # @example
        #   Page::Main::Login.perform do |login|
        #     login.sign_in_as(username: 'username', password: 'password')
        #     login.sign_in_as(username: 'username', password: 'password', accept_terms: false)
        #   end
        def sign_in_as(username:, password:, accept_terms: true)
          self.login_field = username
          self.password_field = password

          sign_in_button
          self.accept_terms if accept_terms && accept_terms?
        end
      end
    end
  end
end

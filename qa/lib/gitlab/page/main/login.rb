# frozen_string_literal: true

module Gitlab
  module Page
    module Main
      class Login < Chemlab::Page
        path '/users/sign_in'

        text_field :login_field
        text_field :password_field
        button :sign_in_button

        def sign_in_as(username:, password:)
          self.login_field = username
          self.password_field = password

          sign_in_button
        end
      end
    end
  end
end

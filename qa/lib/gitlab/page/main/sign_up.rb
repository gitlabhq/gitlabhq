# frozen_string_literal: true

module Gitlab
  module Page
    module Main
      class SignUp < Chemlab::Page
        path '/users/sign_up'

        text_field :first_name, 'data-testid': 'new-user-first-name-field'
        text_field :last_name, 'data-testid': 'new-user-last-name-field'

        text_field :username, 'data-testid': 'new-user-username-field'

        text_field :email, 'data-testid': 'new-user-email-field'
        text_field :password, 'data-testid': 'new-user-password-field'

        button :register, 'data-testid': 'new-user-register-button'

        # Register a user
        # @param [Resource::User] user the user to register
        def register_user(user)
          raise ArgumentError, 'User must be of type Resource::User' unless user.is_a? ::QA::Resource::User

          self.first_name = user.first_name
          self.last_name = user.last_name
          self.username = user.username
          self.email = user.email
          self.password = user.password

          self.register
        end
      end
    end
  end
end

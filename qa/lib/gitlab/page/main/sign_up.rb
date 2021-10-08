# frozen_string_literal: true

module Gitlab
  module Page
    module Main
      class SignUp < Chemlab::Page
        path '/users/sign_up'

        # TODO: Refactor data-qa-selectors to be more terse
        text_field :first_name, 'data-qa-selector': 'new_user_first_name_field'
        text_field :last_name, 'data-qa-selector': 'new_user_last_name_field'

        text_field :username, 'data-qa-selector': 'new_user_username_field'

        text_field :email, 'data-qa-selector': 'new_user_email_field'
        text_field :password, 'data-qa-selector': 'new_user_password_field'

        button :register, 'data-qa-selector': 'new_user_register_button'

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

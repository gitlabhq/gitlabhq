# frozen_string_literal: true

module Slack
  module Page
    class Login < Chemlab::Page
      path '/workspace-signin'

      text_field :workspace_field, data_qa: 'signin_domain_input'
      button :continue_button, data_qa: 'submit_team_domain_button'

      link :sign_in_with_password_link, data_qa: 'sign_in_password_link'

      text_field :email_address_field, data_qa: 'login_email'
      text_field :password_field, data_qa: 'login_password', type: 'password'
      button :sign_in_button, data_qa: 'signin_button'

      def sign_in
        navigate_to_workspace

        # sign into with password if needed
        sign_in_with_password_link_element.click if sign_in_with_password_link_element.exists?

        finish_sign_in
      end

      def navigate_to_workspace
        self.workspace_field = ::QA::Runtime::Env.slack_workspace
        continue_button
      end

      def finish_sign_in
        return unless email_address_field_element.exists?

        self.email_address_field = ::QA::Runtime::Env.slack_email
        self.password_field = ::QA::Runtime::Env.slack_password
        sign_in_button
      end
    end
  end
end

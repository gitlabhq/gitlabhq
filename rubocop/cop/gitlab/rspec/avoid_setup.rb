# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module Gitlab
      module RSpec
        # This cop checks for use of constructs that may lead to deterioration in readability
        # in specs.
        #
        # @example
        #
        #   # bad
        #   before do
        #     enforce_terms
        #   end
        #
        #   it 'auto accepts terms and redirects to the group path' do
        #     visit sso_group_saml_providers_path(group, token: group.saml_discovery_token)
        #
        #     click_link 'Sign in'
        #
        #     expect(page).to have_content('Signed in with SAML')
        #   end
        #
        #   # good
        #   it 'auto accepts terms and redirects to the group path' do
        #     enforce_terms
        #
        #     visit sso_group_saml_providers_path(group, token: group.saml_discovery_token)
        #
        #     click_link 'Sign in'
        #
        #     expect(page).to have_content('Signed in with SAML')
        #   end
        #
        #   # good
        #   it 'registers the user and starts to import a project' do
        #     user_signs_up
        #
        #     expect_to_see_account_confirmation_page
        #
        #     confirm_account
        #
        #     user_signs_in
        #
        #     expect_to_see_welcome_form
        #
        #     fills_in_welcome_form
        #     click_on 'Continue'
        #
        #     expect_to_see_group_and_project_creation_form
        #
        #     click_on 'Import'
        #
        #     expect_to_see_import_form
        #
        #     fills_in_import_form
        #     click_on 'GitHub'
        #
        #     expect_to_be_in_import_process
        #   end
        #
        class AvoidSetup < RuboCop::Cop::Base
          MSG = 'Avoid the use of `%{name}` to keep this area as readable as possible. ' \
              'See https://gitlab.com/gitlab-org/gitlab/-/issues/373194'

          NOT_ALLOWED = %i[let_it_be let_it_be_with_refind let_it_be_with_reload let let!
                           before after around it_behaves_like shared_examples shared_examples_for
                           shared_context include_context subject].freeze

          RESTRICT_ON_SEND = NOT_ALLOWED

          def on_send(node)
            add_offense(node, message: format(MSG, name: node.children[1]))
          end
        end
      end
    end
  end
end

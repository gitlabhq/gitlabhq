# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin sees unconfirmed user', feature_category: :user_management do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user) { create(:omniauth_user, provider: 'twitter', extern_uid: '123456') }
  let_it_be(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
    enable_admin_mode!(current_user, use_ui: true)
  end

  context 'when user has an unconfirmed email', :js do
    let_it_be(:unconfirmed_email) { generate(:email) }
    let_it_be(:unconfirmed_user) { create(:user, :unconfirmed, unconfirmed_email: unconfirmed_email) }

    where(:path_helper) do
      [
        [->(user) { admin_user_path(user) }],
        [->(user) { projects_admin_user_path(user) }],
        [->(user) { keys_admin_user_path(user) }],
        [->(user) { admin_user_identities_path(user) }],
        [->(user) { admin_user_impersonation_tokens_path(user) }]
      ]
    end

    with_them do
      it "allows an admin to force confirmation of the user's email", :aggregate_failures do
        visit path_helper.call(unconfirmed_user)

        click_button 'Confirm user'

        within_modal do
          expect(page).to have_content("Confirm user #{unconfirmed_user.name}?")
          expect(page).to(
            have_content(
              "This user has an unconfirmed email address (#{unconfirmed_email}). You may force a confirmation.")
          )

          click_button 'Confirm user'
        end

        expect(page).to have_content('Successfully confirmed')
        expect(page).not_to have_button('Confirm user')
      end
    end
  end
end

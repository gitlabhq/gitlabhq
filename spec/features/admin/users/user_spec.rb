# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Users::User', feature_category: :user_management do
  include Features::AdminUsersHelpers
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user) { create(:omniauth_user, provider: 'twitter', extern_uid: '123456') }
  let_it_be(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
    gitlab_enable_admin_mode_sign_in(current_user, use_mock_admin_mode: false)
  end

  describe 'GET /admin/users/:id' do
    it 'has user info', :js, :aggregate_failures do
      visit admin_user_path(user)

      expect(page).to have_content(user.email)
      expect(page).to have_content(user.name)
      expect(page).to have_content("ID: #{user.id}")
      expect(page).to have_content("Namespace ID: #{user.namespace_id}")

      click_user_dropdown_toggle(user.id)

      expect(page).to have_button('Block')
      expect(page).to have_button('Deactivate')
      expect(page).to have_button('Delete user')
      expect(page).to have_button('Delete user and contributions')
    end

    context 'when blocking/unblocking the user' do
      it 'shows confirmation and allows blocking and unblocking', :js do
        visit admin_user_path(user)

        click_action_in_user_dropdown(user.id, 'Block')

        expect(page).to have_content('Block user')
        expect(page).to have_content('You can always unblock their account, their data will remain intact.')

        find('.modal-footer button', text: 'Block').click

        wait_for_requests

        expect(page).to have_content('Successfully blocked')

        click_action_in_user_dropdown(user.id, 'Unblock')

        expect(page).to have_content('Unblock user')
        expect(page).to have_content('You can always block their account again if needed.')

        find('.modal-footer button', text: 'Unblock').click

        expect(page).to have_content('Successfully unblocked')

        click_user_dropdown_toggle(user.id)
        expect(page).to have_content('Block')
      end
    end

    context 'when deactivating/re-activating the user' do
      it 'shows confirmation and allows deactivating/re-activating', :js do
        visit admin_user_path(user)

        click_action_in_user_dropdown(user.id, 'Deactivate')

        expect(page).to have_content('Deactivate user')
        expect(page).to have_content('You can always re-activate their account, their data will remain intact.')

        find('.modal-footer button', text: 'Deactivate').click

        wait_for_requests

        expect(page).to have_content('Successfully deactivated')

        click_action_in_user_dropdown(user.id, 'Activate')

        expect(page).to have_content('Activate user')
        expect(page).to have_content('You can always deactivate their account again if needed.')

        find('.modal-footer button', text: 'Activate').click

        wait_for_requests

        expect(page).to have_content('Successfully activated')

        click_user_dropdown_toggle(user.id)
        expect(page).to have_content('Deactivate')
      end
    end

    context 'when user is the sole owner of a group' do
      let_it_be(:group) { create(:group) }
      let_it_be(:user_sole_owner_of_group) { create(:user) }

      before do
        group.add_owner(user_sole_owner_of_group)
      end

      it 'shows `Delete user and contributions` action but not `Delete user` action', :js do
        visit admin_user_path(user_sole_owner_of_group)

        click_user_dropdown_toggle(user_sole_owner_of_group.id)

        expect(page).to have_button('Delete user and contributions')
        expect(page).not_to have_button('Delete user', exact: true)
      end

      it 'allows user to be deleted by using the `Delete user and contributions` action', :js do
        visit admin_user_path(user_sole_owner_of_group)

        click_action_in_user_dropdown(user_sole_owner_of_group.id, 'Delete user and contributions')

        within_modal do
          fill_in('username', with: user_sole_owner_of_group.name)
          click_button('Delete user and contributions')
        end

        wait_for_requests

        expect(page).to have_content('The user is being deleted.')
      end
    end

    context 'when a user is locked', time_travel_to: '2020-02-02 10:30:45 -0700' do
      let_it_be(:locked_user) { create(:user, locked_at: DateTime.parse('2020-02-02 10:30:00 -0700')) }

      before do
        visit admin_user_path(locked_user)
      end

      it "displays `(Locked)` next to user's name" do
        expect(page).to have_content("#{locked_user.name} (Locked)")
      end

      it 'allows a user to be unlocked from the `User administration dropdown', :js do
        accept_gl_confirm("Unlock user #{locked_user.name}?", button_text: 'Unlock') do
          click_action_in_user_dropdown(locked_user.id, 'Unlock')
        end

        expect(page).not_to have_content("#{locked_user.name} (Locked)")
      end
    end

    describe 'Two-factor Authentication status' do
      it 'shows when enabled' do
        user.update!(otp_required_for_login: true)

        visit admin_user_path(user)

        expect_two_factor_status('Enabled')
      end

      it 'shows when disabled' do
        user.update!(otp_required_for_login: false)

        visit admin_user_path(user)

        expect_two_factor_status('Disabled')
      end

      def expect_two_factor_status(status)
        page.within('.two-factor-status') do
          expect(page).to have_content(status)
        end
      end
    end

    describe 'Email verification status' do
      let_it_be(:secondary_email) do
        create :email, email: 'secondary@example.com', user: user
      end

      it 'displays the correct status for an unverified email address', :aggregate_failures do
        user.update!(confirmed_at: nil, unconfirmed_email: user.email)
        visit admin_user_path(user)

        expect(page).to have_content("#{user.email} Unverified")
        expect(page).to have_content("#{secondary_email.email} Unverified")
      end

      it 'displays the correct status for a verified email address' do
        visit admin_user_path(user)
        expect(page).to have_content("#{user.email} Verified")

        secondary_email.confirm
        expect(secondary_email.confirmed?).to be_truthy

        visit admin_user_path(user)
        expect(page).to have_content("#{secondary_email.email} Verified")
      end
    end

    describe 'show user identities' do
      it 'shows user identities', :aggregate_failures do
        visit admin_user_identities_path(user)

        expect(page).to have_content(user.name)
        expect(page).to have_content('twitter')
      end
    end

    describe 'update user identities' do
      before do
        allow(Gitlab::Auth::OAuth::Provider).to receive(:providers).and_return([:twitter, :twitter_updated])
      end

      it 'modifies twitter identity', :aggregate_failures do
        visit admin_user_identities_path(user)

        find('.table').find(:link, 'Edit').click
        fill_in 'identity_extern_uid', with: '654321'
        select 'twitter_updated', from: 'identity_provider'
        click_button 'Save changes'

        expect(page).to have_content(user.name)
        expect(page).to have_content('twitter_updated')
        expect(page).to have_content('654321')
      end
    end

    describe 'remove users secondary email', :js do
      let_it_be(:secondary_email) do
        create :email, email: 'secondary@example.com', user: user
      end

      it do
        visit admin_user_path(user.username)

        expect(page).to have_content("Secondary email: #{secondary_email.email}")

        accept_gl_confirm { find("#remove_email_#{secondary_email.id}").click }

        expect(page).not_to have_content(secondary_email.email)
      end
    end

    describe 'remove user with identities' do
      it 'removes user with twitter identity', :aggregate_failures do
        visit admin_user_identities_path(user)

        click_link 'Delete'

        expect(page).to have_content(user.name)
        expect(page).not_to have_content('twitter')
      end
    end

    describe 'show user keys', :js do
      it do
        key1 = create(:key, user: user, title: 'ssh-rsa Key1')
        key2 = create(:key, user: user, title: 'ssh-rsa Key2')

        visit admin_user_path(user)

        click_link 'SSH keys'

        expect(page).to have_content(key1.title)
        expect(page).to have_content(key2.title)

        click_link key2.title

        expect(page).to have_content(key2.title)
        expect(page).to have_content(key2.key)

        click_button 'Delete'

        page.within('.modal') do
          page.click_button('Delete')
        end

        expect(page).not_to have_content(key2.title)
      end
    end

    describe 'show user attributes' do
      it 'has expected attributes', :aggregate_failures do
        visit admin_user_path(user)

        expect(page).to have_content 'Account'
        expect(page).to have_content 'Personal projects limit'
      end
    end
  end

  context 'when user has an unconfirmed email', :js do
    # Email address contains HTML to ensure email address is displayed in an HTML safe way.
    let_it_be(:unconfirmed_email) { "#{generate(:email)}<h2>testing<img/src=http://localhost:8000/test.png>" }
    let_it_be(:unconfirmed_user) { create(:user, :unconfirmed, unconfirmed_email: unconfirmed_email) }

    where(:path_helper) do
      [
        [-> (user) { admin_user_path(user) }],
        [-> (user) { projects_admin_user_path(user) }],
        [-> (user) { keys_admin_user_path(user) }],
        [-> (user) { admin_user_identities_path(user) }],
        [-> (user) { admin_user_impersonation_tokens_path(user) }]
      ]
    end

    with_them do
      it "allows an admin to force confirmation of the user's email", :aggregate_failures do
        visit path_helper.call(unconfirmed_user)

        click_button 'Confirm user'

        within_modal do
          expect(page).to have_content("Confirm user #{unconfirmed_user.name}?")
          expect(page).to have_content(
            "This user has an unconfirmed email address (#{unconfirmed_email}). You may force a confirmation."
          )

          click_button 'Confirm user'
        end

        expect(page).to have_content('Successfully confirmed')
        expect(page).not_to have_button('Confirm user')
      end
    end
  end
end

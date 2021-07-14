# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Users::User' do
  let_it_be(:user) { create(:omniauth_user, provider: 'twitter', extern_uid: '123456') }
  let_it_be(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
    gitlab_enable_admin_mode_sign_in(current_user)
  end

  describe 'GET /admin/users/:id' do
    it 'has user info', :aggregate_failures do
      visit admin_user_path(user)

      expect(page).to have_content(user.email)
      expect(page).to have_content(user.name)
      expect(page).to have_content("ID: #{user.id}")
      expect(page).to have_content("Namespace ID: #{user.namespace_id}")
      expect(page).to have_button('Deactivate user')
      expect(page).to have_button('Block user')
      expect(page).to have_button('Delete user')
      expect(page).to have_button('Delete user and contributions')
    end

    context 'when blocking/unblocking the user' do
      it 'shows confirmation and allows blocking and unblocking', :js do
        visit admin_user_path(user)

        find('button', text: 'Block user').click

        wait_for_requests

        expect(page).to have_content('Block user')
        expect(page).to have_content('You can always unblock their account, their data will remain intact.')

        find('.modal-footer button', text: 'Block').click

        wait_for_requests

        expect(page).to have_content('Successfully blocked')
        expect(page).to have_content('This user is blocked')

        find('button', text: 'Unblock user').click

        wait_for_requests

        expect(page).to have_content('Unblock user')
        expect(page).to have_content('You can always block their account again if needed.')

        find('.modal-footer button', text: 'Unblock').click

        wait_for_requests

        expect(page).to have_content('Successfully unblocked')
        expect(page).to have_content('Block this user')
      end
    end

    context 'when deactivating/re-activating the user' do
      it 'shows confirmation and allows deactivating/re-activating', :js do
        visit admin_user_path(user)

        find('button', text: 'Deactivate user').click

        wait_for_requests

        expect(page).to have_content('Deactivate user')
        expect(page).to have_content('You can always re-activate their account, their data will remain intact.')

        find('.modal-footer button', text: 'Deactivate').click

        wait_for_requests

        expect(page).to have_content('Successfully deactivated')
        expect(page).to have_content('Reactivate this user')

        find('button', text: 'Activate user').click

        wait_for_requests

        expect(page).to have_content('Activate user')
        expect(page).to have_content('You can always deactivate their account again if needed.')

        find('.modal-footer button', text: 'Activate').click

        wait_for_requests

        expect(page).to have_content('Successfully activated')
        expect(page).to have_content('Deactivate this user')
      end
    end

    describe 'Impersonation' do
      let_it_be(:another_user) { create(:user) }

      context 'before impersonating' do
        subject { visit admin_user_path(user_to_visit) }

        let(:user_to_visit) { another_user }

        context 'for other users' do
          it 'shows impersonate button for other users' do
            subject

            expect(page).to have_content('Impersonate')
          end
        end

        context 'for admin itself' do
          let(:user_to_visit) { current_user }

          it 'does not show impersonate button for admin itself' do
            subject

            expect(page).not_to have_content('Impersonate')
          end
        end

        context 'for blocked user' do
          before do
            another_user.block
          end

          it 'does not show impersonate button for blocked user' do
            subject

            expect(page).not_to have_content('Impersonate')
          end
        end

        context 'when impersonation is disabled' do
          before do
            stub_config_setting(impersonation_enabled: false)
          end

          it 'does not show impersonate button' do
            subject

            expect(page).not_to have_content('Impersonate')
          end
        end
      end

      context 'when impersonating' do
        subject { click_link 'Impersonate' }

        before do
          visit admin_user_path(another_user)
        end

        it 'logs in as the user when impersonate is clicked' do
          subject

          find('[data-qa-selector="user_menu"]').click

          expect(page.find(:css, '[data-testid="user-profile-link"]')['data-user']).to eql(another_user.username)
        end

        it 'sees impersonation log out icon' do
          subject

          icon = first('[data-testid="incognito-icon"]')
          expect(icon).not_to be nil
        end

        context 'a user with an expired password' do
          before do
            another_user.update!(password_expires_at: Time.now - 5.minutes)
          end

          it 'does not redirect to password change page' do
            subject

            expect(current_path).to eq('/')
          end
        end
      end

      context 'ending impersonation' do
        subject { find(:css, 'li.impersonation a').click }

        before do
          visit admin_user_path(another_user)
          click_link 'Impersonate'
        end

        it 'logs out of impersonated user back to original user' do
          subject

          find('[data-qa-selector="user_menu"]').click

          expect(page.find(:css, '[data-testid="user-profile-link"]')['data-user']).to eq(current_user.username)
        end

        it 'is redirected back to the impersonated users page in the admin after stopping' do
          subject

          expect(current_path).to eq("/admin/users/#{another_user.username}")
        end

        context 'a user with an expired password' do
          before do
            another_user.update!(password_expires_at: Time.now - 5.minutes)
          end

          it 'is redirected back to the impersonated users page in the admin after stopping' do
            subject

            expect(current_path).to eq("/admin/users/#{another_user.username}")
          end
        end
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

        accept_confirm { find("#remove_email_#{secondary_email.id}").click }

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
        key1 = create(:key, user: user, title: 'ssh-rsa Key1', key: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4FIEBXGi4bPU8kzxMefudPIJ08/gNprdNTaO9BR/ndy3+58s2HCTw2xCHcsuBmq+TsAqgEidVq4skpqoTMB+Uot5Uzp9z4764rc48dZiI661izoREoKnuRQSsRqUTHg5wrLzwxlQbl1MVfRWQpqiz/5KjBC7yLEb9AbusjnWBk8wvC1bQPQ1uLAauEA7d836tgaIsym9BrLsMVnR4P1boWD3Xp1B1T/ImJwAGHvRmP/ycIqmKdSpMdJXwxcb40efWVj0Ibbe7ii9eeoLdHACqevUZi6fwfbymdow+FeqlkPoHyGg3Cu4vD/D8+8cRc7mE/zGCWcQ15Var83Tczour Key1')
        key2 = create(:key, user: user, title: 'ssh-rsa Key2', key: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQSTWXhJAX/He+nG78MiRRRn7m0Pb0XbcgTxE0etArgoFoh9WtvDf36HG6tOSg/0UUNcp0dICsNAmhBKdncp6cIyPaXJTURPRAGvhI0/VDk4bi27bRnccGbJ/hDaUxZMLhhrzY0r22mjVf8PF6dvv5QUIQVm1/LeaWYsHHvLgiIjwrXirUZPnFrZw6VLREoBKG8uWvfSXw1L5eapmstqfsME8099oi+vWLR8MgEysZQmD28M73fgW4zek6LDQzKQyJx9nB+hJkKUDvcuziZjGmRFlNgSA2mguERwL1OXonD8WYUrBDGKroIvBT39zS5d9tQDnidEJZ9Y8gv5ViYP7x Key2')

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

  describe 'GET /admin/users', :js do
    context 'user pending approval' do
      it 'shows user info', :aggregate_failures do
        user = create(:user, :blocked_pending_approval)

        visit admin_users_path
        click_link 'Pending approval'
        click_link user.name

        expect(page).to have_content(user.name)
        expect(page).to have_content('Pending approval')
        expect(page).to have_link('Approve user')
        expect(page).to have_link('Reject request')
      end
    end
  end

  context 'when user has an unconfirmed email', :js do
    let(:unconfirmed_user) { create(:user, :unconfirmed) }

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

        page.within('[role="dialog"]') do
          expect(page).to have_content("Confirm user #{unconfirmed_user.name}?")
          expect(page).to have_content('This user has an unconfirmed email address. You may force a confirmation.')

          click_button 'Confirm user'
        end

        expect(page).to have_content('Successfully confirmed')
        expect(page).not_to have_button('Confirm user')
      end
    end
  end
end

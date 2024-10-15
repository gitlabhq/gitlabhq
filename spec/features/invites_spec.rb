# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group or Project invitations', :with_current_organization, :aggregate_failures, feature_category: :acquisition do
  let_it_be(:owner) { create(:user, name: 'John Doe') }
  # private will ensure we really have access to the group when we land on the group page
  let_it_be(:group) { create(:group, :private, name: 'Owned') }
  let_it_be(:project) { create(:project, :repository, namespace: group) }

  let(:group_invite) { group.group_members.invite.last }

  before do
    stub_application_setting(require_admin_approval_after_user_signup: false)
    project.add_maintainer(owner)
    group.add_owner(owner)
  end

  context 'when inviting a registered user' do
    let(:invite_email) { 'user@example.com' }

    before do
      group.add_developer(invite_email, owner)
      group_invite.generate_invite_token!
    end

    context 'when signed out' do
      context 'when analyzing the redirects and forms from invite link click' do
        before do
          visit invite_path(group_invite.raw_invite_token)
        end

        it 'renders sign up page with sign up notice' do
          expect(page).to have_current_path(new_user_registration_path, ignore_query: true)
          expect(page).to have_content('To accept this invitation, create an account or sign in')
        end

        it 'pre-fills the "Username or primary email" field on the sign in box with the invite_email from the invite' do
          click_link 'Sign in'

          expect(find_field('Username or primary email').value).to eq(group_invite.invite_email)
        end

        it 'shows the Email to be the invite_email from the invite' do
          expect(find_by_testid('invite-email').text).to eq(group_invite.invite_email)
        end
      end

      context 'when invite is sent before account is created;ldap or service sign in for manual acceptance edge case' do
        let(:user) { create(:user, email: 'user@example.com') }

        context 'when invite clicked and not signed in' do
          before do
            visit invite_path(group_invite.raw_invite_token, invite_type: ::Members::InviteMailer::INITIAL_INVITE)
          end

          it 'sign in, grants access and redirects to group page' do
            click_link 'Sign in'

            gitlab_sign_in(user, remember: true, visit: false)

            expect_to_be_on_group_page(group)
          end
        end

        context 'when signed in and an invite link is clicked' do
          context 'when user is an existing member' do
            before do
              group.add_developer(user)
              sign_in(user)
              visit invite_path(group_invite.raw_invite_token)
            end

            it 'shows message user already a member' do
              expect(page).to have_current_path(invite_path(group_invite.raw_invite_token), ignore_query: true)
              expect(page).to have_content('You are already a member of this group.')
            end
          end

          context 'when email case doesnt match', :js do
            let(:invite_email) { 'User@example.com' }
            let(:user) { create(:user, email: 'user@example.com') }

            before do
              sign_in(user)
              visit invite_path(group_invite.raw_invite_token)
            end

            it 'accepts invite' do
              expect(page)
                .to have_content('You have been granted access to the Owned group with the following role: Developer.')
            end
          end
        end

        context 'when declining the invitation from invitation reminder email' do
          context 'when signed in' do
            before do
              sign_in(user)
              visit decline_invite_path(group_invite.raw_invite_token)
            end

            it 'declines application and redirects to dashboard' do
              expect(page).to have_current_path(dashboard_projects_path)
              expect(page).to have_content('You have declined the invitation to join group Owned.')
              expect { group_invite.reload }.to raise_error ActiveRecord::RecordNotFound
            end
          end

          context 'when signed out with signup onboarding' do
            before do
              visit decline_invite_path(group_invite.raw_invite_token)
            end

            it 'declines application and redirects to sign in page' do
              expect(page).to have_current_path(decline_invite_path(group_invite.raw_invite_token), ignore_query: true)
              expect(page).not_to have_content('You have declined the invitation to join')
              expect(page).to have_content('You successfully declined the invitation')
              expect { group_invite.reload }.to raise_error ActiveRecord::RecordNotFound
            end
          end
        end

        def expect_to_be_on_group_page(group)
          expect(page).to have_current_path(group_path(group))
        end
      end
    end
  end

  context 'when inviting an unregistered user', :js do
    let(:new_user) { build_stubbed(:user) }
    let(:invite_email) { new_user.email }
    let(:group_invite) { create(:group_member, :invited, group: group, invite_email: invite_email, created_by: owner) }
    let(:extra_params) { { invite_type: ::Members::InviteMailer::INITIAL_INVITE } }

    before do
      stub_application_setting_enum('email_confirmation_setting', 'hard')
    end

    context 'when registering using invitation email' do
      before do
        visit invite_path(group_invite.raw_invite_token, extra_params)
      end

      context 'with admin approval required enabled' do
        before do
          stub_application_setting(require_admin_approval_after_user_signup: true)
        end

        it 'does not sign the user in' do
          fill_in_sign_up_form(new_user, invite: true)

          expect(page).to have_current_path(new_user_session_path, ignore_query: true)
          sign_up_message = 'You have signed up successfully. However, we could not sign you in because your account ' \
                            'is awaiting approval from your GitLab administrator.'
          expect(page).to have_content(sign_up_message)
        end
      end

      context 'with email confirmation disabled' do
        before do
          stub_application_setting_enum('email_confirmation_setting', 'off')
        end

        context 'when the user signs up for an account with the invitation email address' do
          it 'redirects to the most recent membership group page with all invitations automatically accepted' do
            fill_in_sign_up_form(new_user, invite: true)

            expect(page).to have_current_path(group_path(group), ignore_query: true)
            expect(page)
              .to have_content('You have been granted access to the Owned group with the following role: Owner.')
          end
        end
      end

      context 'with email confirmation enabled' do
        context 'when user is not valid in sign up form' do
          let(:new_user) { build_stubbed(:user, password: '11111111') }

          it 'fails sign up and redirects back to sign up', :aggregate_failures do
            expect { fill_in_sign_up_form(new_user, invite: true) }.not_to change { User.count }
            expect(page).to have_content('prohibited this user from being saved')
            expect(page).to have_current_path(user_registration_path, ignore_query: true)
            expect(find_by_testid('invite-email').text).to eq(group_invite.invite_email)
          end
        end

        context 'with invite email acceptance', :snowplow do
          it 'tracks the accepted invite' do
            fill_in_sign_up_form(new_user, invite: true)

            expect_snowplow_event(
              category: 'RegistrationsController',
              action: 'accepted',
              label: 'invite_email',
              user: group_invite.reload.user
            )
          end
        end

        context 'when the user signs up for an account with the invitation email address' do
          it 'redirects to the most recent membership group page with all invitations automatically accepted' do
            fill_in_sign_up_form(new_user, invite: true)

            expect(page).to have_current_path(group_path(group), ignore_query: true)
          end
        end
      end

      context 'when the email is already taken by a registered user' do
        before do
          create(:user, email: invite_email)
        end

        it 'shows error state of email already used' do
          fill_in_sign_up_form(new_user, invite: true)

          expect(page).to have_content('Email has already been taken')
          expect(find_by_testid('invite-email').text).to eq(group_invite.invite_email)
        end
      end
    end

    context 'when accepting an invite without an account' do
      it 'lands on sign up page and then registers' do
        visit invite_path(group_invite.raw_invite_token)

        expect(page).to have_current_path(new_user_registration_path, ignore_query: true)

        fill_in_sign_up_form(new_user, invite: true)

        expect(page).to have_current_path(group_path(group))
        expect(page)
          .to have_content('You have been granted access to the Owned group with the following role: Owner.')
      end
    end

    context 'when declining the invitation from invitation reminder email' do
      it 'declines application and shows a decline page' do
        visit decline_invite_path(group_invite.raw_invite_token)

        expect(page).to have_current_path(decline_invite_path(group_invite.raw_invite_token), ignore_query: true)
        expect(page).to have_content('You successfully declined the invitation')
        expect { group_invite.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'when inviting a registered user by a secondary email address' do
      let(:user) { create(:user) }
      let(:secondary_email) { create(:email, user: user) }

      before do
        create(:group_member, :invited, group: group, invite_email: secondary_email.email, created_by: owner)
        gitlab_sign_in(user)
      end

      it 'does not accept the pending invitation and does not redirect to the group path' do
        expect(page).not_to have_current_path(group_path(group), ignore_query: true)
        expect(group.reload).not_to have_user(user)
      end

      context 'when the secondary email address is confirmed' do
        let(:secondary_email) { create(:email, :confirmed, user: user) }

        it 'accepts the pending invitation and redirects to the group path' do
          expect(page).to have_current_path(group_path(group), ignore_query: true)
          expect(group.reload).to have_user(user)
        end
      end
    end
  end
end

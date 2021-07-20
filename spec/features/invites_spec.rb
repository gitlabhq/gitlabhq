# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group or Project invitations', :aggregate_failures do
  let_it_be(:owner) { create(:user, name: 'John Doe') }
  let_it_be(:group) { create(:group, name: 'Owned') }
  let_it_be(:project) { create(:project, :repository, namespace: group) }

  let(:group_invite) { group.group_members.invite.last }

  before do
    stub_application_setting(require_admin_approval_after_user_signup: false)
    project.add_maintainer(owner)
    group.add_owner(owner)
  end

  def confirm_email(new_user)
    new_user_token = User.find_by_email(new_user.email).confirmation_token

    visit user_confirmation_path(confirmation_token: new_user_token)
  end

  def fill_in_sign_up_form(new_user, submit_button_text = 'Register')
    fill_in 'new_user_first_name', with: new_user.first_name
    fill_in 'new_user_last_name', with: new_user.last_name
    fill_in 'new_user_username', with: new_user.username
    fill_in 'new_user_email', with: new_user.email
    fill_in 'new_user_password', with: new_user.password
    click_button submit_button_text
  end

  def fill_in_sign_in_form(user)
    fill_in 'user_login', with: user.email
    fill_in 'user_password', with: user.password
    check 'user_remember_me'
    click_button 'Sign in'
  end

  def fill_in_welcome_form
    select 'Software Developer', from: 'user_role'
    click_button 'Get started!'
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
          expect(current_path).to eq(new_user_registration_path)
          expect(page).to have_content('To accept this invitation, create an account or sign in')
        end

        it 'pre-fills the "Username or email" field on the sign in box with the invite_email from the invite' do
          click_link 'Sign in'

          expect(find_field('Username or email').value).to eq(group_invite.invite_email)
        end

        it 'pre-fills the Email field on the sign up box with the invite_email from the invite' do
          expect(find_field('Email').value).to eq(group_invite.invite_email)
        end
      end

      context 'when invite is sent before account is created - ldap or social sign in for manual acceptance edge case' do
        let(:user) { create(:user, email: 'user@example.com') }

        context 'when invite clicked and not signed in' do
          before do
            visit invite_path(group_invite.raw_invite_token)
          end

          it 'sign in, grants access and redirects to group activity page' do
            click_link 'Sign in'

            fill_in_sign_in_form(user)

            expect(current_path).to eq(activity_group_path(group))
          end
        end

        context 'when signed in and an invite link is clicked' do
          context 'when an invite email is a secondary email for the user' do
            let(:invite_email) { 'user_secondary@example.com' }

            before do
              sign_in(user)
              visit invite_path(group_invite.raw_invite_token)
            end

            it 'sends user to the invite url and allows them to decline' do
              expect(current_path).to eq(invite_path(group_invite.raw_invite_token))
              expect(page).to have_content("Note that this invitation was sent to #{invite_email}")
              expect(page).to have_content("but you are signed in as #{user.to_reference} with email #{user.email}")

              click_link('Decline')

              expect(page).to have_content('You have declined the invitation')
              expect(current_path).to eq(dashboard_projects_path)
              expect { group_invite.reload }.to raise_error ActiveRecord::RecordNotFound
            end

            it 'sends uer to the invite url and allows them to accept' do
              expect(current_path).to eq(invite_path(group_invite.raw_invite_token))
              expect(page).to have_content("Note that this invitation was sent to #{invite_email}")
              expect(page).to have_content("but you are signed in as #{user.to_reference} with email #{user.email}")

              click_link('Accept invitation')

              expect(page).to have_content('You have been granted')
              expect(current_path).to eq(activity_group_path(group))
            end
          end

          context 'when user is an existing member' do
            before do
              sign_in(owner)
              visit invite_path(group_invite.raw_invite_token)
            end

            it 'shows message user already a member' do
              expect(current_path).to eq(invite_path(group_invite.raw_invite_token))
              expect(page).to have_link(owner.name, href: user_url(owner))
              expect(page).to have_content('However, you are already a member of this group.')
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
              expect(current_path).to eq(dashboard_projects_path)
              expect(page).to have_content('You have declined the invitation to join group Owned.')
              expect { group_invite.reload }.to raise_error ActiveRecord::RecordNotFound
            end
          end

          context 'when signed out with signup onboarding' do
            before do
              visit decline_invite_path(group_invite.raw_invite_token)
            end

            it 'declines application and redirects to sign in page' do
              expect(current_path).to eq(decline_invite_path(group_invite.raw_invite_token))
              expect(page).not_to have_content('You have declined the invitation to join')
              expect(page).to have_content('You successfully declined the invitation')
              expect { group_invite.reload }.to raise_error ActiveRecord::RecordNotFound
            end
          end
        end
      end
    end
  end

  context 'when inviting an unregistered user' do
    let(:new_user) { build_stubbed(:user) }
    let(:invite_email) { new_user.email }
    let(:group_invite) { create(:group_member, :invited, group: group, invite_email: invite_email, created_by: owner) }
    let(:send_email_confirmation) { true }

    before do
      stub_application_setting(send_user_confirmation_email: send_email_confirmation)
    end

    context 'when registering using invitation email' do
      before do
        visit invite_path(group_invite.raw_invite_token, invite_type: Members::InviteEmailExperiment::INVITE_TYPE)
      end

      context 'with admin approval required enabled' do
        before do
          stub_application_setting(require_admin_approval_after_user_signup: true)
        end

        it 'does not sign the user in' do
          fill_in_sign_up_form(new_user)

          expect(current_path).to eq(new_user_session_path)
          expect(page).to have_content('You have signed up successfully. However, we could not sign you in because your account is awaiting approval from your GitLab administrator')
        end
      end

      context 'email confirmation disabled' do
        let(:send_email_confirmation) { false }

        it 'signs up and redirects to the most recent membership activity page with all the projects/groups invitations automatically accepted' do
          fill_in_sign_up_form(new_user)
          fill_in_welcome_form

          expect(current_path).to eq(activity_group_path(group))
          expect(page).to have_content('You have been granted Owner access to group Owned.')
        end

        context 'the user sign-up using a different email address' do
          let(:invite_email) { build_stubbed(:user).email }

          it 'signs up and redirects to the activity page' do
            fill_in_sign_up_form(new_user)
            fill_in_welcome_form

            expect(current_path).to eq(activity_group_path(group))
          end
        end
      end

      context 'email confirmation enabled' do
        context 'with members/invite_email experiment', :experiment do
          it 'tracks the accepted invite' do
            expect(experiment('members/invite_email')).to track(:accepted)
                                                            .with_context(actor: group_invite)
                                                            .on_next_instance

            fill_in_sign_up_form(new_user)
          end
        end

        it 'signs up and redirects to the group activity page with all the project/groups invitation automatically accepted' do
          fill_in_sign_up_form(new_user)
          fill_in_welcome_form

          expect(current_path).to eq(activity_group_path(group))
        end

        context 'the user sign-up using a different email address' do
          let(:invite_email) { build_stubbed(:user).email }

          context 'when soft email confirmation is not enabled' do
            before do
              stub_feature_flags(soft_email_confirmation: false)
              allow(User).to receive(:allow_unconfirmed_access_for).and_return 0
            end

            it 'signs up and redirects to the group activity page' do
              fill_in_sign_up_form(new_user)
              confirm_email(new_user)
              fill_in_sign_in_form(new_user)
              fill_in_welcome_form

              expect(current_path).to eq(activity_group_path(group))
            end
          end

          context 'when soft email confirmation is enabled' do
            before do
              stub_feature_flags(soft_email_confirmation: true)
              allow(User).to receive(:allow_unconfirmed_access_for).and_return 2.days
            end

            it 'signs up and redirects to the group activity page' do
              fill_in_sign_up_form(new_user)
              fill_in_welcome_form

              expect(current_path).to eq(activity_group_path(group))
            end
          end
        end
      end
    end

    context 'when accepting an invite without an account' do
      it 'lands on sign up page and then registers' do
        visit invite_path(group_invite.raw_invite_token)

        expect(current_path).to eq(new_user_registration_path)

        fill_in_sign_up_form(new_user, 'Register')

        expect(current_path).to eq(users_sign_up_welcome_path)
      end
    end

    context 'when declining the invitation from invitation reminder email' do
      it 'declines application and shows a decline page' do
        visit decline_invite_path(group_invite.raw_invite_token)

        expect(current_path).to eq(decline_invite_path(group_invite.raw_invite_token))
        expect(page).to have_content('You successfully declined the invitation')
        expect { group_invite.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe 'Invites' do
  let(:user) { create(:user) }
  let(:owner) { create(:user, name: 'John Doe') }
  let(:group) { create(:group, name: 'Owned') }
  let(:project) { create(:project, :repository, namespace: group) }
  let(:group_invite) { group.group_members.invite.last }

  before do
    stub_feature_flags(invisible_captcha: false)
    project.add_maintainer(owner)
    group.add_user(owner, Gitlab::Access::OWNER)
    group.add_developer('user@example.com', owner)
    group_invite.generate_invite_token!
  end

  def confirm_email_and_sign_in(new_user)
    new_user_token = User.find_by_email(new_user.email).confirmation_token

    visit user_confirmation_path(confirmation_token: new_user_token)
    fill_in_sign_in_form(new_user)
  end

  def fill_in_sign_up_form(new_user)
    fill_in 'new_user_name',                with: new_user.name
    fill_in 'new_user_username',            with: new_user.username
    fill_in 'new_user_email',               with: new_user.email
    fill_in 'new_user_email_confirmation',  with: new_user.email
    fill_in 'new_user_password',            with: new_user.password
    click_button "Register"
  end

  def fill_in_sign_in_form(user)
    fill_in 'user_login', with: user.email
    fill_in 'user_password', with: user.password
    check 'user_remember_me'
    click_button 'Sign in'
  end

  context 'when signed out' do
    before do
      visit invite_path(group_invite.raw_invite_token)
    end

    it 'renders sign in page with sign in notice' do
      expect(current_path).to eq(new_user_session_path)
      expect(page).to have_content('To accept this invitation, sign in')
    end

    it 'sign in and redirects to invitation page' do
      fill_in_sign_in_form(user)

      expect(current_path).to eq(invite_path(group_invite.raw_invite_token))
      expect(page).to have_content(
        'You have been invited by John Doe to join group Owned as Developer.'
      )
      expect(page).to have_link('Accept invitation')
      expect(page).to have_link('Decline')
    end
  end

  context 'when signed in as an exists member' do
    before do
      sign_in(owner)
    end

    it 'shows message user already a member' do
      visit invite_path(group_invite.raw_invite_token)
      expect(page).to have_content('However, you are already a member of this group.')
    end
  end

  describe 'accepting the invitation' do
    before do
      sign_in(user)
      visit invite_path(group_invite.raw_invite_token)
    end

    it 'grants access and redirects to group page' do
      page.click_link 'Accept invitation'
      expect(current_path).to eq(group_path(group))
      expect(page).to have_content(
        'You have been granted Developer access to group Owned.'
      )
    end
  end

  describe 'declining the application' do
    context 'when signed in' do
      before do
        sign_in(user)
        visit invite_path(group_invite.raw_invite_token)
      end

      it 'declines application and redirects to dashboard' do
        page.click_link 'Decline'
        expect(current_path).to eq(dashboard_projects_path)
        expect(page).to have_content(
          'You have declined the invitation to join group Owned.'
        )
      end
    end

    context 'when signed out' do
      before do
        visit decline_invite_path(group_invite.raw_invite_token)
      end

      it 'declines application and redirects to sign in page' do
        expect(current_path).to eq(new_user_session_path)
        expect(page).to have_content(
          'You have declined the invitation to join group Owned.'
        )
      end
    end
  end

  describe 'invite an user using their email address' do
    let(:new_user) { build_stubbed(:user) }
    let(:invite_email) { new_user.email }
    let(:group_invite) { create(:group_member, :invited, group: group, invite_email: invite_email) }
    let!(:project_invite) { create(:project_member, :invited, project: project, invite_email: invite_email) }

    before do
      stub_application_setting(send_user_confirmation_email: send_email_confirmation)
      visit invite_path(group_invite.raw_invite_token)
    end

    context 'email confirmation disabled' do
      let(:send_email_confirmation) { false }

      it 'signs up and redirects to the dashboard page with all the projects/groups invitations automatically accepted' do
        fill_in_sign_up_form(new_user)

        expect(current_path).to eq(dashboard_projects_path)
        expect(page).to have_content(project.full_name)
        visit group_path(group)
        expect(page).to have_content(group.full_name)
      end

      context 'the user sign-up using a different email address' do
        let(:invite_email) { build_stubbed(:user).email }

        it 'signs up and redirects to the invitation page' do
          fill_in_sign_up_form(new_user)

          expect(current_path).to eq(invite_path(group_invite.raw_invite_token))
        end
      end
    end

    context 'email confirmation enabled' do
      let(:send_email_confirmation) { true }

      it 'signs up and redirects to root page with all the project/groups invitation automatically accepted' do
        fill_in_sign_up_form(new_user)
        confirm_email_and_sign_in(new_user)

        expect(current_path).to eq(root_path)
        expect(page).to have_content(project.full_name)
        visit group_path(group)
        expect(page).to have_content(group.full_name)
      end

      it "doesn't accept invitations until the user confirm his email" do
        fill_in_sign_up_form(new_user)
        sign_in(owner)

        visit project_project_members_path(project)
        expect(page).to have_content 'Invited'
      end

      context 'the user sign-up using a different email address' do
        let(:invite_email) { build_stubbed(:user).email }

        it 'signs up and redirects to the invitation page' do
          fill_in_sign_up_form(new_user)
          confirm_email_and_sign_in(new_user)

          expect(current_path).to eq(invite_path(group_invite.raw_invite_token))
        end
      end
    end
  end
end

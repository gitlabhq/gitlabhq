require 'spec_helper'

describe 'Invites' do
  let(:user) { create(:user) }
  let(:owner) { create(:user, name: 'John Doe') }
  let(:group) { create(:group, name: 'Owned') }
  let(:project) { create(:project, :repository, namespace: group) }
  let(:invite) { group.group_members.invite.last }

  before do
    project.add_master(owner)
    group.add_user(owner, Gitlab::Access::OWNER)
    group.add_developer('user@example.com', owner)
    invite.generate_invite_token!
  end

  context 'when signed out' do
    before do
      visit invite_path(invite.raw_invite_token)
    end

    it 'renders sign in page with sign in notice' do
      expect(current_path).to eq(new_user_session_path)
      expect(page).to have_content('To accept this invitation, sign in')
    end

    it 'sign in and redirects to invitation page' do
      fill_in 'user_login', with: user.email
      fill_in 'user_password', with: user.password
      check 'user_remember_me'
      click_button 'Sign in'

      expect(current_path).to eq(invite_path(invite.raw_invite_token))
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
      visit invite_path(invite.raw_invite_token)
      expect(page).to have_content('However, you are already a member of this group.')
    end
  end

  describe 'accepting the invitation' do
    before do
      sign_in(user)
      visit invite_path(invite.raw_invite_token)
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
        visit invite_path(invite.raw_invite_token)
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
        visit decline_invite_path(invite.raw_invite_token)
      end

      it 'declines application and redirects to sign in page' do
        expect(current_path).to eq(new_user_session_path)
        expect(page).to have_content(
          'You have declined the invitation to join group Owned.'
        )
      end
    end
  end
end

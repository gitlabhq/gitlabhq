require 'spec_helper'

describe 'User visits the authentication log' do
  let(:user) { create(:user) }

  context 'when user signed in' do
    before do
      sign_in(user)
    end

    it 'shows correct menu item' do
      visit(audit_log_profile_path)

      expect(page).to have_active_navigation('Authentication log')
    end
  end

  context 'when user has activity' do
    before do
      create(:closed_issue_event, author: user)
      gitlab_sign_in(user)
    end

    it 'shows user activity' do
      visit(audit_log_profile_path)

      expect(page).to have_content 'Signed in with standard authentication'
    end
  end
end

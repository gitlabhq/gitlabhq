require 'spec_helper'

describe 'User visits the authentication log' do
  let(:user) { create(:user) }

  before do
    sign_in(user)

    visit(audit_log_profile_path)
  end

  it 'shows correct menu item' do
    expect(page).to have_active_navigation('Authentication log')
  end
end

require 'spec_helper'

describe 'User visits the profile account page' do
  let(:user) { create(:user) }

  before do
    sign_in(user)

    visit(profile_account_path)
  end

  it 'shows correct menu item' do
    expect(find('.sidebar-top-level-items > li.active')).to have_content('Account')
    expect(page).to have_selector('.sidebar-top-level-items > li.active', count: 1)
  end
end

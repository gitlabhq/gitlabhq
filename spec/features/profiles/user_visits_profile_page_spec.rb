require 'spec_helper'

describe 'User visits the profile page' do
  let(:user) { create(:user) }

  before do
    sign_in(user)

    visit(profile_path)
  end

  it 'shows correct menu item' do
    expect(find('.sidebar-top-level-items > li.active')).to have_content('Profile')
    expect(page).to have_selector('.sidebar-top-level-items > li.active', count: 1)
  end
end

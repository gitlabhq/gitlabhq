require 'spec_helper'

describe 'User visits their profile' do
  let(:user) { create(:user) }

  before do
    sign_in(user)

    visit(profile_path)
  end

  it 'shows correct menu item' do
    expect(page).to have_active_navigation('Profile')
  end
end

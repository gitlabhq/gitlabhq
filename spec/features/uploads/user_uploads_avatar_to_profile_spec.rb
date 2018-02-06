require 'rails_helper'

feature 'User uploads avatar to profile' do
  scenario 'they see their new avatar' do
    user = create(:user)
    sign_in(user)

    visit profile_path
    attach_file(
      'user_avatar',
      Rails.root.join('spec', 'fixtures', 'dk.png'),
      visible: false
    )

    click_button 'Update profile settings'

    visit user_path(user)

    expect(page).to have_selector(%Q(img[data-src$="/uploads/-/system/user/avatar/#{user.id}/dk.png"]))

    # Cheating here to verify something that isn't user-facing, but is important
    expect(user.reload.avatar.file).to exist
  end
end

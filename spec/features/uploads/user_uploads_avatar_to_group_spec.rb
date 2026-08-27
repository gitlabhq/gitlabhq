# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User uploads avatar to group', feature_category: :user_profile do
  it 'they see the new avatar' do
    user = create(:user)
    group = create(:group)
    group.add_owner(user)
    sign_in(user)

    visit edit_group_path(group)
    attach_file(
      'group_avatar',
      Rails.root.join('spec', 'fixtures', 'dk.png'),
      visible: false
    )

    within_testid('general-settings') do
      click_button 'Save changes'
    end

    visit group_path(group)

    avatar_src = page.find(%(img[src*="/uploads/-/system/group/avatar/#{group.id}/dk.png?"]))['src']
    expect(avatar_src).to include("width=")

    # Cheating here to verify something that isn't user-facing, but is important
    expect(group.reload.avatar.file).to exist
  end
end

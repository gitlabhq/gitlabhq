require 'spec_helper'

feature 'Groups > Members > Last owner cannot leave group', feature: true do
  let(:owner) { create(:user) }
  let(:group) { create(:group) }

  background do
    group.add_owner(owner)
    login_as(owner)
    visit group_path(group)
  end

  scenario 'user does not see a "Leave Group" link' do
    expect(page).not_to have_content 'Leave Group'
  end
end

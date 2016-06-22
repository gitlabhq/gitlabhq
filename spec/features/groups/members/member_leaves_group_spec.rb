require 'spec_helper'

feature 'Groups > Members > Member leaves group', feature: true do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:group) { create(:group, :public) }

  background do
    group.add_owner(owner)
    group.add_developer(user)
    login_as(user)
    visit group_path(group)
  end

  scenario 'user leaves group' do
    click_link 'Leave Group'

    expect(current_path).to eq(dashboard_groups_path)
    expect(group.users.exists?(user.id)).to be_falsey
  end
end

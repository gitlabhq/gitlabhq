require 'spec_helper'

feature 'Groups > Members > Leave group' do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:group) { create(:group) }

  background do
    gitlab_sign_in(user)
  end

  scenario 'guest leaves the group' do
    group.add_guest(user)
    group.add_owner(other_user)

    visit group_path(group)
    click_link 'Leave group'

    expect(current_path).to eq(dashboard_groups_path)
    expect(page).to have_content left_group_message(group)
    expect(group.users).not_to include(user)
  end

  scenario 'guest leaves the group as last member' do
    group.add_guest(user)

    visit group_path(group)
    click_link 'Leave group'

    expect(current_path).to eq(dashboard_groups_path)
    expect(page).to have_content left_group_message(group)
    expect(group.users).not_to include(user)
  end

  scenario 'owner leaves the group if they is not the last owner' do
    group.add_owner(user)
    group.add_owner(other_user)

    visit group_path(group)
    click_link 'Leave group'

    expect(current_path).to eq(dashboard_groups_path)
    expect(page).to have_content left_group_message(group)
    expect(group.users).not_to include(user)
  end

  scenario 'owner can not leave the group if they is a last owner' do
    group.add_owner(user)

    visit group_path(group)

    expect(page).not_to have_content 'Leave group'

    visit group_group_members_path(group)

    expect(find(:css, '.project-members-page li', text: user.name)).not_to have_selector(:css, 'a.btn-remove')
  end

  def left_group_message(group)
    "You left the \"#{group.name}\""
  end
end

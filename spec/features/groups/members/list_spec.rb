require 'spec_helper'

feature 'Groups members list', feature: true do
  include Select2Helper

  let(:user1) { create(:user, name: 'John Doe') }
  let(:user2) { create(:user, name: 'Mary Jane') }
  let(:group) { create(:group) }
  let(:nested_group) { create(:group, parent: group) }

  background do
    login_as(user1)
  end

  scenario 'show members from current group and parent' do
    group.add_developer(user1)
    nested_group.add_developer(user2)

    visit group_group_members_path(nested_group)

    expect(first_row.text).to include(user1.name)
    expect(second_row.text).to include(user2.name)
  end

  scenario 'show user once if member of both current group and parent' do
    group.add_developer(user1)
    nested_group.add_developer(user1)

    visit group_group_members_path(nested_group)

    expect(first_row.text).to include(user1.name)
    expect(second_row).to be_blank
  end

  scenario 'update user to owner level', :js do
    group.add_owner(user1)
    group.add_developer(user2)

    visit group_group_members_path(group)

    page.within(second_row) do
      click_button('Developer')
      click_link('Owner')

      expect(page).to have_button('Owner')
    end
  end

  scenario 'add user to group', :js do
    group.add_owner(user1)

    visit group_group_members_path(group)

    add_user(user2.id, 'Reporter')

    page.within(second_row) do
      expect(page).to have_content(user2.name)
      expect(page).to have_button('Reporter')
    end
  end

  scenario 'add yourself to group when already an owner', :js do
    group.add_owner(user1)

    visit group_group_members_path(group)

    add_user(user1.id, 'Reporter')

    page.within(first_row) do
      expect(page).to have_content(user1.name)
      expect(page).to have_content('Owner')
    end
  end

  scenario 'invite user to group', :js do
    group.add_owner(user1)

    visit group_group_members_path(group)

    add_user('test@example.com', 'Reporter')

    page.within(second_row) do
      expect(page).to have_content('test@example.com')
      expect(page).to have_content('Invited')
      expect(page).to have_button('Reporter')
    end
  end

  def first_row
    page.all('ul.content-list > li')[0]
  end

  def second_row
    page.all('ul.content-list > li')[1]
  end

  def add_user(id, role)
    page.within ".users-group-form" do
      select2(id, from: "#user_ids", multiple: true)
      select(role, from: "access_level")
    end

    click_button "Add to group"
  end
end

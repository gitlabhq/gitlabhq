require 'spec_helper'

feature 'Groups > Members > Manage members' do
  include Select2Helper

  let(:user1) { create(:user, name: 'John Doe') }
  let(:user2) { create(:user, name: 'Mary Jane') }
  let(:group) { create(:group) }

  background do
    sign_in(user1)
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

  scenario 'remove user from group', :js do
    group.add_owner(user1)
    group.add_developer(user2)

    visit group_group_members_path(group)

    find(:css, '.project-members-page li', text: user2.name).find(:css, 'a.btn-remove').click

    expect(page).not_to have_content(user2.name)
    expect(group.users).not_to include(user2)
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

  scenario 'guest can not manage other users' do
    group.add_guest(user1)
    group.add_developer(user2)

    visit group_group_members_path(group)

    expect(page).not_to have_button 'Add to group'

    page.within(second_row) do
      # Can not modify user2 role
      expect(page).not_to have_button 'Developer'

      # Can not remove user2
      expect(page).not_to have_css('a.btn-remove')
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

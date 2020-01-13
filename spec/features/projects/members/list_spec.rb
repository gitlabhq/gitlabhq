# frozen_string_literal: true

require 'spec_helper'

describe 'Project members list' do
  include Select2Helper
  include Spec::Support::Helpers::Features::ListRowsHelpers

  let(:user1) { create(:user, name: 'John Doe') }
  let(:user2) { create(:user, name: 'Mary Jane') }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }

  before do
    sign_in(user1)
    group.add_owner(user1)
  end

  it 'show members from project and group' do
    project.add_developer(user2)

    visit_members_page

    expect(first_row.text).to include(user1.name)
    expect(second_row.text).to include(user2.name)
  end

  it 'show user once if member of both group and project' do
    project.add_developer(user1)

    visit_members_page

    expect(first_row.text).to include(user1.name)
    expect(second_row).to be_blank
  end

  it 'update user acess level', :js do
    project.add_developer(user2)

    visit_members_page

    page.within(second_row) do
      click_button('Developer')
      click_link('Reporter')

      expect(page).to have_button('Reporter')
    end
  end

  it 'add user to project', :js do
    visit_members_page

    add_user(user2.id, 'Reporter')

    page.within(second_row) do
      expect(page).to have_content(user2.name)
      expect(page).to have_button('Reporter')
    end
  end

  it 'remove user from project', :js do
    other_user = create(:user)
    project.add_developer(other_user)

    visit_members_page

    accept_confirm do
      find(:css, 'li.project_member', text: other_user.name).find(:css, 'a.btn-remove').click
    end

    wait_for_requests

    expect(page).not_to have_content(other_user.name)
    expect(project.users).not_to include(other_user)
  end

  it 'invite user to project', :js do
    visit_members_page

    add_user('test@example.com', 'Reporter')

    page.within(second_row) do
      expect(page).to have_content('test@example.com')
      expect(page).to have_content('Invited')
      expect(page).to have_button('Reporter')
    end
  end

  def add_user(id, role)
    page.within ".invite-users-form" do
      select2(id, from: "#user_ids", multiple: true)
      select(role, from: "access_level")
    end

    click_button "Invite"
  end

  def visit_members_page
    visit project_settings_members_path(project)
  end
end

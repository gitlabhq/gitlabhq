require 'spec_helper'

feature 'Groups > Members > List members' do
  include Select2Helper

  let(:user1) { create(:user, name: 'John Doe') }
  let(:user2) { create(:user, name: 'Mary Jane') }
  let(:group) { create(:group) }
  let(:nested_group) { create(:group, parent: group) }

  background do
    gitlab_sign_in(user1)
  end

  scenario 'show members from current group and parent', :nested_groups do
    group.add_developer(user1)
    nested_group.add_developer(user2)

    visit group_group_members_path(nested_group)

    expect(first_row.text).to include(user1.name)
    expect(second_row.text).to include(user2.name)
  end

  scenario 'show user once if member of both current group and parent', :nested_groups do
    group.add_developer(user1)
    nested_group.add_developer(user1)

    visit group_group_members_path(nested_group)

    expect(first_row.text).to include(user1.name)
    expect(second_row).to be_blank
  end

  def first_row
    page.all('ul.content-list > li')[0]
  end

  def second_row
    page.all('ul.content-list > li')[1]
  end
end

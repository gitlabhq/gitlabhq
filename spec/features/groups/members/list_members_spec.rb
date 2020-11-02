# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > List members', :js do
  include Spec::Support::Helpers::Features::MembersHelpers

  let(:user1) { create(:user, name: 'John Doe') }
  let(:user2) { create(:user, name: 'Mary Jane') }
  let(:group) { create(:group) }
  let(:nested_group) { create(:group, parent: group) }

  before do
    sign_in(user1)
  end

  it 'show members from current group and parent' do
    group.add_developer(user1)
    nested_group.add_developer(user2)

    visit group_group_members_path(nested_group)

    expect(first_row.text).to include(user1.name)
    expect(second_row.text).to include(user2.name)
  end

  it 'show user once if member of both current group and parent' do
    group.add_developer(user1)
    nested_group.add_developer(user1)

    visit group_group_members_path(nested_group)

    expect(first_row.text).to include(user1.name)
    expect(second_row).to be_blank
  end

  describe 'showing status of members' do
    before do
      group.add_developer(user2)
    end

    it 'shows the status' do
      create(:user_status, user: user2, emoji: 'smirk', message: 'Authoring this object')

      visit group_group_members_path(nested_group)

      expect(first_row).to have_selector('gl-emoji[data-name="smirk"]')
    end
  end
end

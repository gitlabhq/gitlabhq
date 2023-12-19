# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Search group member', :js, feature_category: :groups_and_projects do
  include Features::MembersHelpers

  let(:user) { create :user }
  let(:member) { create :user }

  let!(:guest_group) do
    create(:group) do |group|
      group.add_guest(user)
      group.add_guest(member)
    end
  end

  before do
    sign_in(user)
    visit group_group_members_path(guest_group)
  end

  it 'renders member users' do
    within_testid('members-filtered-search-bar') do
      find_field('Filter members').click
      find('input').native.send_keys(member.name)
      click_button 'Search'
    end

    expect(members_table).to have_content(member.name)
    expect(members_table).not_to have_content(user.name)
  end
end

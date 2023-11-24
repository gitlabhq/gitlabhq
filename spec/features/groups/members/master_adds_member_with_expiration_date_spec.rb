# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Owner adds member with expiration date', :js, feature_category: :groups_and_projects do
  include Features::MembersHelpers
  include Features::InviteMembersModalHelpers

  let_it_be(:user1) { create(:user, name: 'John Doe') }
  let_it_be(:group) { create(:group) }
  let_it_be(:expiration_date) { 5.days.from_now.to_date }

  let(:new_member) { create(:user, name: 'Mary Jane') }

  before do
    group.add_owner(user1)
    sign_in(user1)
  end

  it 'expiration date is displayed in the members list' do
    visit group_group_members_path(group)

    invite_member(new_member.name, role: 'Guest', expires_at: expiration_date)

    page.within second_row do
      expect(page).to have_field('Expiration date', with: expiration_date)
    end
  end

  it 'changes expiration date' do
    group.add_developer(new_member)
    visit group_group_members_path(group)

    page.within second_row do
      fill_in 'Expiration date', with: expiration_date
      find_field('Expiration date').native.send_keys :enter

      wait_for_requests

      expect(page).to have_field('Expiration date', with: expiration_date)
    end
  end

  it 'clears expiration date' do
    create(:group_member, :developer, user: new_member, group: group, expires_at: expiration_date)
    visit group_group_members_path(group)

    page.within second_row do
      expect(page).to have_field('Expiration date', with: expiration_date)

      find_by_testid('clear-button').click

      wait_for_requests

      expect(page).to have_field('Expiration date', with: '')
    end
  end
end

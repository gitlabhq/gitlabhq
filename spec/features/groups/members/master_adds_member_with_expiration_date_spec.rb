# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Members > Owner adds member with expiration date', :js do
  include Select2Helper
  include ActiveSupport::Testing::TimeHelpers

  let_it_be(:user1) { create(:user, name: 'John Doe') }
  let_it_be(:group) { create(:group) }
  let(:new_member) { create(:user, name: 'Mary Jane') }

  before do
    stub_feature_flags(vue_group_members_list: false)

    travel_to Time.now.utc.beginning_of_day

    group.add_owner(user1)
    sign_in(user1)
  end

  it 'expiration date is displayed in the members list' do
    visit group_group_members_path(group)

    page.within '.invite-users-form' do
      select2(new_member.id, from: '#user_ids', multiple: true)

      fill_in 'expires_at', with: 3.days.from_now.to_date
      find_field('expires_at').native.send_keys :enter

      click_on 'Invite'
    end

    page.within "#group_member_#{group_member_id}" do
      expect(page).to have_content('Expires in 3 days')
    end
  end

  it 'changes expiration date' do
    group.add_developer(new_member)
    visit group_group_members_path(group)

    page.within "#group_member_#{group_member_id}" do
      fill_in 'Expiration date', with: 3.days.from_now.to_date
      find_field('Expiration date').native.send_keys :enter

      wait_for_requests

      expect(page).to have_content('Expires in 3 days')
    end
  end

  it 'clears expiration date' do
    create(:group_member, :developer, user: new_member, group: group, expires_at: 3.days.from_now.to_date)
    visit group_group_members_path(group)

    page.within "#group_member_#{group_member_id}" do
      expect(page).to have_content('Expires in 3 days')

      find('.js-clear-input').click

      wait_for_requests

      expect(page).not_to have_content('Expires in')
    end
  end

  def group_member_id
    group.members.find_by(user_id: new_member).id
  end
end

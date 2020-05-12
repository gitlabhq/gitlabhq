# frozen_string_literal: true

require 'spec_helper'

describe 'Groups > Members > Owner adds member with expiration date', :js do
  include Select2Helper
  include ActiveSupport::Testing::TimeHelpers

  let(:user1) { create(:user, name: 'John Doe') }
  let!(:new_member) { create(:user, name: 'Mary Jane') }
  let(:group) { create(:group) }

  before do
    group.add_owner(user1)
    sign_in(user1)
  end

  it 'expiration date is displayed in the members list' do
    travel_to Time.zone.parse('2016-08-06 08:00') do
      date = 4.days.from_now
      visit group_group_members_path(group)

      page.within '.invite-users-form' do
        select2(new_member.id, from: '#user_ids', multiple: true)
        fill_in 'expires_at', with: date.to_s(:medium) + "\n"
        click_on 'Invite'
      end

      page.within "#group_member_#{group_member_id(new_member)}" do
        expect(page).to have_content('Expires in 4 days')
      end
    end
  end

  it 'change expiration date' do
    travel_to Time.zone.parse('2016-08-06 08:00') do
      date = 3.days.from_now
      group.add_developer(new_member)

      visit group_group_members_path(group)

      page.within "#group_member_#{group_member_id(new_member)}" do
        find('.js-access-expiration-date').set date.to_s(:medium) + "\n"
        wait_for_requests
        expect(page).to have_content('Expires in 3 days')
      end
    end
  end

  it 'remove expiration date' do
    travel_to Time.zone.parse('2016-08-06 08:00') do
      date = 3.days.from_now
      group_member = create(:group_member, :developer, user: new_member, group: group, expires_at: date.to_s(:medium))

      visit group_group_members_path(group)

      page.within "#group_member_#{group_member.id}" do
        find('.js-clear-input').click
        wait_for_requests
        expect(page).not_to have_content('Expires in 3 days')
      end
    end
  end

  def group_member_id(user)
    group.members.find_by(user_id: new_member).id
  end
end

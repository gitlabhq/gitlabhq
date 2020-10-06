# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Maintainer adds member with expiration date', :js do
  include Select2Helper
  include ActiveSupport::Testing::TimeHelpers

  let_it_be(:maintainer) { create(:user) }
  let_it_be(:project) { create(:project) }
  let(:new_member) { create(:user) }

  before do
    travel_to Time.now.utc.beginning_of_day

    project.add_maintainer(maintainer)
    sign_in(maintainer)
  end

  it 'expiration date is displayed in the members list' do
    visit project_project_members_path(project)

    page.within '.invite-users-form' do
      select2(new_member.id, from: '#user_ids', multiple: true)

      fill_in 'expires_at', with: 3.days.from_now.to_date
      find_field('expires_at').native.send_keys :enter

      click_on 'Invite'
    end

    page.within "#project_member_#{project_member_id}" do
      expect(page).to have_content('Expires in 3 days')
    end
  end

  it 'changes expiration date' do
    project.team.add_users([new_member.id], :developer, expires_at: Date.today.to_date)
    visit project_project_members_path(project)

    page.within "#project_member_#{project_member_id}" do
      fill_in 'Expiration date', with: 3.days.from_now.to_date
      find_field('Expiration date').native.send_keys :enter

      wait_for_requests

      expect(page).to have_content('Expires in 3 days')
    end
  end

  it 'clears expiration date' do
    project.team.add_users([new_member.id], :developer, expires_at: 3.days.from_now.to_date)
    visit project_project_members_path(project)

    page.within "#project_member_#{project_member_id}" do
      expect(page).to have_content('Expires in 3 days')

      find('.js-clear-input').click

      wait_for_requests

      expect(page).not_to have_content('Expires in')
    end
  end

  def project_member_id
    project.members.find_by(user_id: new_member).id
  end
end

require 'spec_helper'

feature 'Projects > Members > Master adds member with expiration date', :js do
  include Select2Helper
  include ActiveSupport::Testing::TimeHelpers

  let(:master) { create(:user) }
  let(:project) { create(:project) }
  let!(:new_member) { create(:user) }

  background do
    project.add_master(master)
    sign_in(master)
  end

  scenario 'expiration date is displayed in the members list' do
    travel_to Time.zone.parse('2016-08-06 08:00') do
      date = 4.days.from_now
      visit project_project_members_path(project)

      page.within '.users-project-form' do
        select2(new_member.id, from: '#user_ids', multiple: true)
        fill_in 'expires_at', with: date.to_s(:medium) + "\n"
        click_on 'Add to project'
      end

      page.within "#project_member_#{new_member.project_members.first.id}" do
        expect(page).to have_content('Expires in 4 days')
      end
    end
  end

  scenario 'change expiration date' do
    travel_to Time.zone.parse('2016-08-06 08:00') do
      date = 3.days.from_now
      project.team.add_users([new_member.id], :developer, expires_at: Date.today.to_s(:medium))
      visit project_project_members_path(project)

      page.within "#project_member_#{new_member.project_members.first.id}" do
        find('.js-access-expiration-date').set date.to_s(:medium) + "\n"
        wait_for_requests
        expect(page).to have_content('Expires in 3 days')
      end
    end
  end
end

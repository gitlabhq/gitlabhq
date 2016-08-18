require 'spec_helper'

feature 'Projects > Members > Master adds member with expiration date', feature: true, js: true do
  include Select2Helper
  include ActiveSupport::Testing::TimeHelpers

  let(:master) { create(:user) }
  let(:project) { create(:project) }
  let!(:new_member) { create(:user) }

  background do
    project.team << [master, :master]
    login_as(master)
  end

  scenario 'expiration date is displayed in the members list' do
    travel_to Time.zone.parse('2016-08-06 08:00') do
      visit namespace_project_project_members_path(project.namespace, project)

      page.within '.users-project-form' do
        select2(new_member.id, from: '#user_ids', multiple: true)
        fill_in 'expires_at', with: '2016-08-10'
        click_on 'Add users to project'
      end

      page.within '.project_member:first-child' do
        expect(page).to have_content('Expires in 4 days')
      end
    end
  end

  scenario 'change expiration date' do
    travel_to Time.zone.parse('2016-08-06 08:00') do
      project.team.add_users([new_member.id], :developer, expires_at: '2016-09-06')
      visit namespace_project_project_members_path(project.namespace, project)

      page.within '.project_member:first-child' do
        click_on 'Edit'
        fill_in 'Access expiration date', with: '2016-08-09'
        click_on 'Save'
        expect(page).to have_content('Expires in 3 days')
      end
    end
  end
end

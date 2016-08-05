require 'spec_helper'

feature 'Projects > Members > Master adds member with expiration date', feature: true, js: true do
  include Select2Helper

  let!(:master) { create(:user) }
  let!(:project) { create(:project) }
  let!(:new_member) { create(:user) }

  background do
    project.team << [master, :master]
    login_as(master)
  end

  scenario 'expiration date is displayed in the members list' do
    visit namespace_project_project_members_path(project.namespace, project)

    page.within '.users-project-form' do
      select2(new_member.id, from: '#user_ids', multiple: true)
      fill_in 'Access expiration date', with: 4.days.from_now
      click_on 'Add users to project'
    end

    page.within '.project_member:first-child' do
      expect(page).to have_content('Expires in 4 days')
    end
  end

  scenario 'change expiration date' do
    project.team.add_users([new_member.id], :developer, expires_at: 1.month.from_now)
    visit namespace_project_project_members_path(project.namespace, project)

    page.within '.project_member:first-child' do
      click_on 'Edit'
      fill_in 'Access expiration date', with: 2.days.from_now
      click_on 'Save'
      expect(page).to have_content('Expires in 2 days')
    end
  end
end

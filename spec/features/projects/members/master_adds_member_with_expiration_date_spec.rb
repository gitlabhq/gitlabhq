require 'spec_helper'

feature 'Projects > Members > Master adds member with expiration date', feature: true, js: true do
  include Select2Helper

  let!(:master) { create(:user) }
  let!(:project) { create(:project) }
  let!(:new_member) { create(:user) }

  background do
    project.team << [master, :master]
    login_as(master)
    visit namespace_project_project_members_path(project.namespace, project)
  end

  scenario 'expiration date is displayed in the members list' do
    page.within ".users-project-form" do
      select2(new_member.id, from: "#user_ids", multiple: true)
      fill_in "Access expiration date", with: 4.days.from_now
      click_on "Add users to project"
    end

    page.within ".project_member:first-child" do
      expect(page).to have_content("Expires in 4 days")
    end
  end
end

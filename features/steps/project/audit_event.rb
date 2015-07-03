class Spinach::Features::AuditEvent < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'I created new depoloy key' do
    visit new_namespace_project_deploy_key_path(@project.namespace, @project)

    fill_in "deploy_key_title", with: "laptop"
    fill_in "deploy_key_key", with: "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAzrEJUIR6Y03TCE9rIJ+GqTBvgb8t1jI9h5UBzCLuK4VawOmkLornPqLDrGbm6tcwM/wBrrLvVOqi2HwmkKEIecVO0a64A4rIYScVsXIniHRS6w5twyn1MD3sIbN+socBDcaldECQa2u1dI3tnNVcs8wi77fiRe7RSxePsJceGoheRQgC8AZ510UdIlO+9rjIHUdVN7LLyz512auAfYsgx1OfablkQ/XJcdEwDNgi9imI6nAXhmoKUm1IPLT2yKajTIC64AjLOnE0YyCh6+7RFMpiMyu1qiOCpdjYwTgBRiciNRZCH8xIedyCoAmiUgkUT40XYHwLuwiPJICpkAzp7Q== user@laptop"

    click_button "Create"
  end

  step 'I remove deploy key' do
    visit namespace_project_deploy_keys_path(@project.namespace, @project)
    click_link "Remove"
  end

  step 'I see remove deploy key event' do
    expect(page).to have_content("Remove deploy key")
  end

  step 'I see deploy key event' do
    expect(page).to have_content("Add deploy key")
  end

  step 'I should see the audit event listed' do
    page.within('table#audits') do
      expect(page).to have_content "Change access level from developer to master"
      expect(page).to have_content(project.owner.name)
      expect(page).to have_content('Pete')
    end
  end

  step 'gitlab user "Pete"' do
    create(:user, name: "Pete")
  end

  step '"Pete" is "Shop" developer' do
    user = User.find_by(name: "Pete")
    project = Project.find_by(name: "Shop")
    project.team << [user, :developer]
  end

  step 'I go to "Members"' do
    find(:link, 'Members').trigger('click')
  end

  step 'I visit project "Shop" settings page' do
    find(:link, 'Settings').trigger('click')
  end

  step 'I change "Pete" access level to master' do
    user = User.find_by(name: "Pete")
    project_member = @project.project_members.find_by(user_id: user)

    page.within "#project_member_#{project_member.id}" do
      click_button "Edit access level"
      select "Master", from: "project_member_access_level"
      click_button "Save"
    end

    sleep 0.05
  end

  step 'I go to "Audit Events"' do
    find(:link, 'Audit Events').trigger('click')
  end
end

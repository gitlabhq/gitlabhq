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
end

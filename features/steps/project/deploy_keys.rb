class Spinach::Features::ProjectDeployKeys < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'project has deploy key' do
    create(:deploy_keys_project, project: @project)
  end

  step 'I should see project deploy keys' do
    within '.enabled-keys' do
      page.should have_content deploy_key.title
    end
  end

  step 'I click \'New Deploy Key\'' do
    click_link 'New Deploy Key'
  end

  step 'I submit new deploy key' do
    fill_in "deploy_key_title", with: "laptop"
    fill_in "deploy_key_key", with: "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAzrEJUIR6Y03TCE9rIJ+GqTBvgb8t1jI9h5UBzCLuK4VawOmkLornPqLDrGbm6tcwM/wBrrLvVOqi2HwmkKEIecVO0a64A4rIYScVsXIniHRS6w5twyn1MD3sIbN+socBDcaldECQa2u1dI3tnNVcs8wi77fiRe7RSxePsJceGoheRQgC8AZ510UdIlO+9rjIHUdVN7LLyz512auAfYsgx1OfablkQ/XJcdEwDNgi9imI6nAXhmoKUm1IPLT2yKajTIC64AjLOnE0YyCh6+7RFMpiMyu1qiOCpdjYwTgBRiciNRZCH8xIedyCoAmiUgkUT40XYHwLuwiPJICpkAzp7Q== user@laptop"
    click_button "Create"
  end

  step 'I should be on deploy keys page' do
    current_path.should == project_deploy_keys_path(@project)
  end

  step 'I should see newly created deploy key' do
    within '.enabled-keys' do
      page.should have_content(deploy_key.title)
    end
  end

  step 'other project has deploy key' do
    @second_project = create :project, namespace: create(:group)
    @second_project.team << [current_user, :master]
    create(:deploy_keys_project, project: @second_project)
  end

  step 'I click attach deploy key' do
    within '.available-keys' do
      click_link 'Enable'
    end
  end

  protected

  def deploy_key
    @project.deploy_keys.last
  end
end

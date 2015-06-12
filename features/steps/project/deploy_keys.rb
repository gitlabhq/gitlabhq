class Spinach::Features::ProjectDeployKeys < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'project has deploy key' do
    create(:deploy_keys_project, project: @project)
  end

  step 'I should see project deploy key' do
    page.within '.enabled-keys' do
      expect(page).to have_content deploy_key.title
    end
  end

  step 'I should see other project deploy key' do
    page.within '.available-keys' do
      expect(page).to have_content other_deploy_key.title
    end
  end

  step 'I should see public deploy key' do
    page.within '.available-keys' do
      expect(page).to have_content public_deploy_key.title
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
    expect(current_path).to eq namespace_project_deploy_keys_path(@project.namespace, @project)
  end

  step 'I should see newly created deploy key' do
    page.within '.enabled-keys' do
      expect(page).to have_content(deploy_key.title)
    end
  end

  step 'other projects have deploy keys' do
    @second_project = create(:project, namespace: create(:group))
    @second_project.team << [current_user, :master]
    create(:deploy_keys_project, project: @second_project)

    @third_project = create(:project, namespace: create(:group))
    @third_project.team << [current_user, :master]
    create(:deploy_keys_project, project: @third_project, deploy_key: @second_project.deploy_keys.first)
  end

  step 'I should only see the same deploy key once' do
    page.within '.available-keys' do
      expect(page).to have_selector('ul li', count: 1)
    end
  end

  step 'public deploy key exists' do
    create(:deploy_key, public: true)
  end

  step 'I click attach deploy key' do
    page.within '.available-keys' do
      click_link 'Enable'
    end
  end

  protected

  def deploy_key
    @project.deploy_keys.last
  end

  def other_deploy_key
    @second_project.deploy_keys.last
  end

  def public_deploy_key
    DeployKey.are_public.last
  end
end

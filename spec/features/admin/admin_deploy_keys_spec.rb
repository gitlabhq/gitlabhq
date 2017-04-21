require 'spec_helper'

RSpec.describe 'admin deploy keys', type: :feature do
  let!(:deploy_key) { create(:deploy_key, public: true) }
  let!(:another_deploy_key) { create(:another_deploy_key, public: true) }

  before do
    login_as(:admin)
  end

  it 'show all public deploy keys' do
    visit admin_deploy_keys_path

    expect(page).to have_content(deploy_key.title)
    expect(page).to have_content(another_deploy_key.title)
  end

  describe 'create new deploy key' do
    before do
      visit admin_deploy_keys_path
      click_link 'New deploy key'
    end

    it 'creates new deploy key' do
      fill_deploy_key
      click_button 'Create'

      expect_renders_new_key
    end

    it 'creates new deploy key with write access' do
      fill_deploy_key
      check "deploy_key_can_push"
      click_button "Create"

      expect_renders_new_key
      expect(page).to have_content('Yes')
    end

    def expect_renders_new_key
      expect(current_path).to eq admin_deploy_keys_path
      expect(page).to have_content('laptop')
    end

    def fill_deploy_key
      fill_in 'deploy_key_title', with: 'laptop'
      fill_in 'deploy_key_key', with: 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAzrEJUIR6Y03TCE9rIJ+GqTBvgb8t1jI9h5UBzCLuK4VawOmkLornPqLDrGbm6tcwM/wBrrLvVOqi2HwmkKEIecVO0a64A4rIYScVsXIniHRS6w5twyn1MD3sIbN+socBDcaldECQa2u1dI3tnNVcs8wi77fiRe7RSxePsJceGoheRQgC8AZ510UdIlO+9rjIHUdVN7LLyz512auAfYsgx1OfablkQ/XJcdEwDNgi9imI6nAXhmoKUm1IPLT2yKajTIC64AjLOnE0YyCh6+7RFMpiMyu1qiOCpdjYwTgBRiciNRZCH8xIedyCoAmiUgkUT40XYHwLuwiPJICpkAzp7Q== user@laptop'
    end
  end
end

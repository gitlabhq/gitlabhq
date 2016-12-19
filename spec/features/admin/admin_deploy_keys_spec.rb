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

  it 'creates new deploy key' do
    visit admin_deploy_keys_path

    click_link 'New Deploy Key'
    fill_in 'deploy_key_title', with: 'laptop'
    fill_in 'deploy_key_key', with: 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAzrEJUIR6Y03TCE9rIJ+GqTBvgb8t1jI9h5UBzCLuK4VawOmkLornPqLDrGbm6tcwM/wBrrLvVOqi2HwmkKEIecVO0a64A4rIYScVsXIniHRS6w5twyn1MD3sIbN+socBDcaldECQa2u1dI3tnNVcs8wi77fiRe7RSxePsJceGoheRQgC8AZ510UdIlO+9rjIHUdVN7LLyz512auAfYsgx1OfablkQ/XJcdEwDNgi9imI6nAXhmoKUm1IPLT2yKajTIC64AjLOnE0YyCh6+7RFMpiMyu1qiOCpdjYwTgBRiciNRZCH8xIedyCoAmiUgkUT40XYHwLuwiPJICpkAzp7Q== user@laptop'
    click_button 'Create'

    expect(current_path).to eq admin_deploy_keys_path
    expect(page).to have_content('laptop')
  end
end

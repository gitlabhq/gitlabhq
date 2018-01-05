require 'spec_helper'

RSpec.describe 'admin deploy keys' do
  let!(:deploy_key) { create(:deploy_key, public: true) }
  let!(:another_deploy_key) { create(:another_deploy_key, public: true) }

  before do
    sign_in(create(:admin))
  end

  it 'show all public deploy keys' do
    visit admin_deploy_keys_path

    page.within(find('.deploy-keys-list', match: :first)) do
      expect(page).to have_content(deploy_key.title)
      expect(page).to have_content(another_deploy_key.title)
    end
  end

  it 'shows all the projects the deploy key has write access' do
    write_key = create(:deploy_keys_project, :write_access, deploy_key: deploy_key)

    visit admin_deploy_keys_path

    page.within(find('.deploy-keys-list', match: :first)) do
      expect(page).to have_content(write_key.project.full_name)
    end
  end

  describe 'create a new deploy key' do
    let(:new_ssh_key) { attributes_for(:key)[:key] }

    before do
      visit admin_deploy_keys_path
      click_link 'New deploy key'
    end

    it 'creates a new deploy key' do
      fill_in 'deploy_key_title', with: 'laptop'
      fill_in 'deploy_key_key', with: new_ssh_key
      click_button 'Create'

      expect(current_path).to eq admin_deploy_keys_path

      page.within(find('.deploy-keys-list', match: :first)) do
        expect(page).to have_content('laptop')
      end
    end
  end

  describe 'update an existing deploy key' do
    before do
      visit admin_deploy_keys_path
      find('tr', text: deploy_key.title).click_link('Edit')
    end

    it 'updates an existing deploy key' do
      fill_in 'deploy_key_title', with: 'new-title'
      click_button 'Save changes'

      expect(current_path).to eq admin_deploy_keys_path

      page.within(find('.deploy-keys-list', match: :first)) do
        expect(page).to have_content('new-title')
      end
    end
  end

  describe 'remove an existing deploy key' do
    before do
      visit admin_deploy_keys_path
    end

    it 'removes an existing deploy key' do
      find('tr', text: deploy_key.title).click_link('Remove')

      expect(current_path).to eq admin_deploy_keys_path
      page.within(find('.deploy-keys-list', match: :first)) do
        expect(page).not_to have_content(deploy_key.title)
      end
    end
  end
end

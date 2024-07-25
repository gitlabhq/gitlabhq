# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin deploy keys', :js, feature_category: :system_access do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:admin) { create(:admin) }

  let!(:deploy_key) { create(:deploy_key, public: true) }
  let!(:another_deploy_key) { create(:another_deploy_key, public: true) }

  before do
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  describe 'index page' do
    before do
      visit admin_deploy_keys_path
    end

    it 'show all public deploy keys' do
      within_testid('deploy-keys-list', match: :first) do
        expect(page).to have_content(deploy_key.title)
        expect(page).to have_content(another_deploy_key.title)
      end
    end

    it 'shows breadcrumbs' do
      expect(page_breadcrumbs).to eq([
        { text: 'Admin area', href: admin_root_path },
        { text: 'Deploy keys', href: admin_deploy_keys_path }
      ])
    end
  end

  it 'shows all the projects the deploy key has write access' do
    write_key = create(:deploy_keys_project, :write_access, deploy_key: deploy_key)

    visit admin_deploy_keys_path

    within_testid('deploy-keys-list', match: :first) do
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

      expect(page).to have_current_path admin_deploy_keys_path, ignore_query: true

      within_testid('deploy-keys-list', match: :first) do
        expect(page).to have_content('laptop')
      end
    end

    it 'shows breadcrumbs' do
      expect(page_breadcrumbs).to eq([
        { text: 'Admin area', href: admin_root_path },
        { text: 'Deploy keys', href: admin_deploy_keys_path },
        { text: 'New deploy key', href: new_admin_deploy_key_path }
      ])
    end
  end

  describe 'update an existing deploy key' do
    before do
      visit admin_deploy_keys_path
      page.within('tr', text: deploy_key.title) do
        click_link(_('Edit deploy key'))
      end
    end

    it 'updates an existing deploy key' do
      fill_in 'deploy_key_title', with: 'new-title'
      click_button 'Save changes'

      expect(page).to have_current_path admin_deploy_keys_path, ignore_query: true

      within_testid('deploy-keys-list', match: :first) do
        expect(page).to have_content('new-title')
      end
    end

    it 'shows breadcrumbs' do
      expect(page_breadcrumbs).to eq([
        { text: 'Admin area', href: admin_root_path },
        { text: 'Deploy keys', href: admin_deploy_keys_path },
        { text: 'Edit deploy key', href: edit_admin_deploy_key_path(deploy_key) }
      ])
    end
  end

  describe 'remove an existing deploy key' do
    before do
      visit admin_deploy_keys_path
    end

    it 'removes an existing deploy key' do
      accept_gl_confirm('Are you sure you want to delete this deploy key?', button_text: 'Delete') do
        page.within('tr', text: deploy_key.title) do
          click_button _('Delete deploy key')
        end
      end

      expect(page).to have_current_path admin_deploy_keys_path, ignore_query: true
      within_testid('deploy-keys-list', match: :first) do
        expect(page).not_to have_content(deploy_key.title)
      end
    end
  end
end

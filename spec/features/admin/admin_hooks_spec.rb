require 'spec_helper'

describe 'Admin::Hooks', feature: true do
  before do
    @project = create(:project)
    login_as :admin

    @system_hook = create(:system_hook)
  end

  describe 'GET /admin/hooks' do
    it 'is ok' do
      visit admin_root_path

      page.within '.layout-nav' do
        click_on 'Hooks'
      end

      expect(current_path).to eq(admin_hooks_path)
    end

    it 'has hooks list' do
      visit admin_hooks_path
      expect(page).to have_content(@system_hook.url)
    end
  end

  describe 'New Hook' do
    let(:url) { generate(:url) }

    it 'adds new hook' do
      visit admin_hooks_path
      fill_in 'hook_url', with: url
      check 'Enable SSL verification'

      expect { click_button 'Add system hook' }.to change(SystemHook, :count).by(1)
      expect(page).to have_content 'SSL Verification: enabled'
      expect(current_path).to eq(admin_hooks_path)
      expect(page).to have_content(url)
    end
  end

  describe 'Update existing hook' do
    let(:new_url) { generate(:url) }

    it 'updates existing hook' do
      visit admin_hooks_path

      click_link 'Edit'
      fill_in 'hook_url', with: new_url
      check 'Enable SSL verification'
      click_button 'Save changes'

      expect(page).to have_content 'SSL Verification: enabled'
      expect(current_path).to eq(admin_hooks_path)
      expect(page).to have_content(new_url)
    end
  end

  describe 'Remove existing hook' do
    it 'remove existing hook' do
      visit admin_hooks_path

      expect { click_link 'Remove' }.to change(SystemHook, :count).by(-1)
    end
  end

  describe 'Test' do
    before do
      WebMock.stub_request(:post, @system_hook.url)
      visit admin_hooks_path
      click_link 'Test hook'
    end

    it { expect(current_path).to eq(admin_hooks_path) }
  end
end

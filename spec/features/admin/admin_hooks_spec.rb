# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Hooks', feature_category: :webhooks do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user) { create(:admin) }

  before do
    sign_in(user)
    enable_admin_mode!(user)
  end

  describe 'GET /admin/hooks' do
    it 'is ok', :js do
      visit admin_root_path

      within_testid('super-sidebar') do
        click_on 'System hooks', match: :first
      end

      expect(page).to have_current_path(admin_hooks_path, ignore_query: true)
    end

    it 'has hooks list' do
      system_hook = create(:system_hook)

      visit admin_hooks_path
      expect(page).to have_content(system_hook.url)
    end

    it 'renders plugins list as well' do
      allow(Gitlab::FileHook).to receive(:files).and_return(['foo.rb', 'bar.clj'])

      visit admin_hooks_path

      expect(page).to have_content('File hooks')
      expect(page).to have_content('foo.rb')
      expect(page).to have_content('bar.clj')
    end
  end

  describe 'New Hook' do
    let(:url) { generate(:url) }

    it 'adds new hook' do
      visit admin_hooks_path

      click_button 'Add new webhook'
      fill_in 'hook_url', with: url
      check 'Enable SSL verification'

      expect { click_button 'Add webhook' }.to change(SystemHook, :count).by(1)
      expect(page).to have_content 'SSL Verification: enabled'
      expect(page).to have_current_path(admin_hooks_path, ignore_query: true)
      expect(page).to have_content(url)
    end
  end

  describe 'Update existing hook' do
    let(:new_url) { generate(:url) }
    let_it_be(:hook) { create(:system_hook) }

    it 'updates existing hook' do
      visit admin_hooks_path

      click_link 'Edit'
      fill_in 'hook_url', with: new_url
      check 'Enable SSL verification'
      click_button 'Save changes'

      expect(page).to have_content('Enable SSL verification')
      expect(page).to have_current_path(edit_admin_hook_path(hook), ignore_query: true)
      expect(page).to have_content('Recent events')
    end
  end

  describe 'Remove existing hook', :js do
    let(:hook_url) { generate(:url) }

    before do
      create(:system_hook, url: hook_url)
    end

    context 'removes existing hook' do
      it 'from hooks list page' do
        visit admin_hooks_path

        accept_gl_confirm(button_text: 'Delete webhook') { click_link 'Delete' }
        expect(page).not_to have_content(hook_url)
      end

      it 'from hook edit page' do
        visit admin_hooks_path
        click_link 'Edit'

        accept_gl_confirm(button_text: 'Delete webhook') { click_link 'Delete' }
        expect(page).not_to have_content(hook_url)
      end
    end
  end

  describe 'Test', :js do
    before do
      system_hook = create(:system_hook)
      WebMock.stub_request(:post, system_hook.url)
      visit admin_hooks_path

      click_button 'Test'
      click_link 'Push events'
    end

    it { expect(page).to have_current_path(admin_hooks_path, ignore_query: true) }
  end

  context 'Merge request hook' do
    describe 'New Hook' do
      let(:url) { generate(:url) }

      it 'adds new hook' do
        visit admin_hooks_path

        click_button 'Add new webhook'
        fill_in 'hook_url', with: url
        uncheck 'Repository update events'
        check 'Merge request events'

        expect { click_button 'Add webhook' }.to change(SystemHook, :count).by(1)
        expect(page).to have_current_path(admin_hooks_path, ignore_query: true)
        expect(page).to have_content(url)
      end
    end

    describe 'Test', :js do
      before do
        system_hook = create(:system_hook)
        WebMock.stub_request(:post, system_hook.url)
      end

      it 'succeeds if the user has a repository with a merge request' do
        project = create(:project, :repository)
        create(:project_member, user: user, project: project)
        create(:merge_request, source_project: project)

        visit admin_hooks_path
        click_button 'Test'
        click_link 'Merge request events'

        expect(page).to have_content 'Hook executed successfully'
      end
    end
  end
end

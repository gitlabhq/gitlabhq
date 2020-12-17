# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin uses repository checks', :request_store do
  include StubENV

  let(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
  end

  context 'when admin mode is disabled' do
    it 'admin project page requires admin mode' do
      project = create(:project)
      visit_admin_project_page(project)

      expect(page).not_to have_css('.repository-check')
      expect(page).to have_content('Enter Admin Mode')
    end
  end

  context 'when admin mode is enabled' do
    before do
      gitlab_enable_admin_mode_sign_in(admin)
    end

    it 'to trigger a single check', :js do
      project = create(:project)
      visit_admin_project_page(project)

      page.within('.repository-check') do
        click_button 'Trigger repository check'
      end

      expect(page).to have_content('Repository check was triggered')
    end

    it 'to see a single failed repository check', :js do
      project = create(:project)
      project.update_columns(
        last_repository_check_failed: true,
        last_repository_check_at: Time.now
      )
      visit_admin_project_page(project)

      page.within('[data-testid="last-repository-check-failed-alert"]') do
        expect(page.text).to match(/Last repository check \(just now\) failed/)
      end
    end

    it 'to clear all repository checks', :js do
      visit repository_admin_application_settings_path

      expect(RepositoryCheck::ClearWorker).to receive(:perform_async)

      accept_confirm { find(:link, 'Clear all repository checks').send_keys(:return) }

      expect(page).to have_content('Started asynchronous removal of all repository check states.')
    end
  end

  def visit_admin_project_page(project)
    visit admin_project_path(project)
  end
end

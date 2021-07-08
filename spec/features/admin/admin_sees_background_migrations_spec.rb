# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin > Admin sees background migrations" do
  let_it_be(:admin) { create(:admin) }

  let_it_be(:active_migration) { create(:batched_background_migration, table_name: 'active', status: :active) }
  let_it_be(:failed_migration) { create(:batched_background_migration, table_name: 'failed', status: :failed, total_tuple_count: 100) }
  let_it_be(:finished_migration) { create(:batched_background_migration, table_name: 'finished', status: :finished) }

  before_all do
    create(:batched_background_migration_job, batched_migration: failed_migration, batch_size: 30, status: :succeeded)
  end

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  it 'can navigate to background migrations' do
    visit admin_root_path

    within '.nav-sidebar' do
      link = find_link 'Background Migrations'

      link.click

      expect(page).to have_current_path(admin_background_migrations_path)
      expect(link).to have_ancestor(:css, 'li.active')
    end
  end

  it 'can view queued migrations and pause and resume them' do
    visit admin_background_migrations_path

    within '#content-body' do
      expect(page).to have_selector('tbody tr', count: 1)

      expect(page).to have_content(active_migration.job_class_name)
      expect(page).to have_content(active_migration.table_name)
      expect(page).to have_content('0.00%')
      expect(page).not_to have_content('Paused')
      expect(page).to have_content('Active')

      click_button('Pause')
      expect(page).not_to have_content('Active')
      expect(page).to have_content('Paused')

      click_button('Resume')
      expect(page).not_to have_content('Paused')
      expect(page).to have_content('Active')
    end
  end

  it 'can view failed migrations' do
    visit admin_background_migrations_path

    within '#content-body' do
      tab = find_link 'Failed'
      tab.click

      expect(page).to have_current_path(admin_background_migrations_path(tab: 'failed'))
      expect(tab[:class]).to include('gl-tab-nav-item-active', 'gl-tab-nav-item-active-indigo')

      expect(page).to have_selector('tbody tr', count: 1)

      expect(page).to have_content(failed_migration.job_class_name)
      expect(page).to have_content(failed_migration.table_name)
      expect(page).to have_content('30.00%')
      expect(page).to have_content(failed_migration.status.humanize)
    end
  end

  it 'can view finished migrations' do
    visit admin_background_migrations_path

    within '#content-body' do
      tab = find_link 'Finished'
      tab.click

      expect(page).to have_current_path(admin_background_migrations_path(tab: 'finished'))
      expect(tab[:class]).to include('gl-tab-nav-item-active', 'gl-tab-nav-item-active-indigo')

      expect(page).to have_selector('tbody tr', count: 1)

      expect(page).to have_content(finished_migration.job_class_name)
      expect(page).to have_content(finished_migration.table_name)
      expect(page).to have_content('100.00%')
      expect(page).to have_content(finished_migration.status.humanize)
    end
  end
end

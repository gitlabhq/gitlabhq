# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin > Admin sees background migrations" do
  let_it_be(:admin) { create(:admin) }

  let_it_be(:active_migration) { create(:batched_background_migration, table_name: 'active', status: :active) }
  let_it_be(:failed_migration) { create(:batched_background_migration, table_name: 'failed', status: :failed, total_tuple_count: 100) }
  let_it_be(:finished_migration) { create(:batched_background_migration, table_name: 'finished', status: :finished) }

  before_all do
    create(:batched_background_migration_job, :failed, batched_migration: failed_migration, batch_size: 10, min_value: 6, max_value: 15, attempts: 3)
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

  context 'when there are failed migrations' do
    before do
      allow_next_instance_of(Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy) do |batch_class|
        allow(batch_class).to receive(:next_batch).with(anything, anything, batch_min_value: 6, batch_size: 5).and_return([6, 10])
      end
    end

    it 'can view and retry them' do
      visit admin_background_migrations_path

      within '#content-body' do
        tab = find_link 'Failed'
        tab.click

        expect(page).to have_current_path(admin_background_migrations_path(tab: 'failed'))
        expect(tab[:class]).to include('gl-tab-nav-item-active')

        expect(page).to have_selector('tbody tr', count: 1)

        expect(page).to have_content(failed_migration.job_class_name)
        expect(page).to have_content(failed_migration.table_name)
        expect(page).to have_content('0.00%')
        expect(page).to have_content(failed_migration.status.humanize)

        click_button('Retry')
        expect(page).not_to have_content(failed_migration.job_class_name)
        expect(page).not_to have_content(failed_migration.table_name)
        expect(page).not_to have_content('0.00%')
      end
    end
  end

  it 'can view finished migrations' do
    visit admin_background_migrations_path

    within '#content-body' do
      tab = find_link 'Finished'
      tab.click

      expect(page).to have_current_path(admin_background_migrations_path(tab: 'finished'))
      expect(tab[:class]).to include('gl-tab-nav-item-active')

      expect(page).to have_selector('tbody tr', count: 1)

      expect(page).to have_content(finished_migration.job_class_name)
      expect(page).to have_content(finished_migration.table_name)
      expect(page).to have_content('100.00%')
      expect(page).to have_content(finished_migration.status.humanize)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Jobs', :js, feature_category: :continuous_integration do
  before do
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  describe 'GET /admin/jobs' do
    let(:pipeline) { create(:ci_pipeline) }

    context 'All tab' do
      context 'when have jobs' do
        it 'shows all jobs', :js do
          create(:ci_build, pipeline: pipeline, status: :pending)
          create(:ci_build, pipeline: pipeline, status: :running)
          create(:ci_build, pipeline: pipeline, status: :success)
          create(:ci_build, pipeline: pipeline, status: :failed)

          visit admin_jobs_path

          wait_for_requests

          expect(page).to have_selector('[data-testid="jobs-all-tab"]')
          expect(page.all('[data-testid="jobs-table-row"]').size).to eq(4)
          expect(page).to have_button 'Cancel all jobs'

          click_button 'Cancel all jobs'
          expect(page).to have_button 'Yes, proceed'
          expect(page).to have_content 'Are you sure?'
        end
      end

      context 'when have no jobs' do
        it 'shows a message' do
          visit admin_jobs_path

          wait_for_requests

          expect(page).to have_selector('[data-testid="jobs-all-tab"]')
          expect(page).to have_selector('[data-testid="jobs-empty-state"]')
          expect(page).not_to have_button 'Cancel all jobs'
        end
      end
    end

    context 'Finished tab' do
      context 'when have finished jobs' do
        it 'shows finished jobs' do
          build1 = create(:ci_build, pipeline: pipeline, status: :pending)
          build2 = create(:ci_build, pipeline: pipeline, status: :running)
          build3 = create(:ci_build, pipeline: pipeline, status: :success)

          visit admin_jobs_path

          wait_for_requests

          find_by_testid('jobs-finished-tab').click

          wait_for_requests

          expect(page).to have_selector('[data-testid="jobs-finished-tab"]')
          expect(find_by_testid('job-id-link')).not_to have_content(build1.id)
          expect(find_by_testid('job-id-link')).not_to have_content(build2.id)
          expect(find_by_testid('job-id-link')).to have_content(build3.id)
          expect(page).to have_button 'Cancel all jobs'
        end
      end

      context 'when have no jobs finished' do
        it 'shows a message' do
          create(:ci_build, pipeline: pipeline, status: :running)

          visit admin_jobs_path

          wait_for_requests

          find_by_testid('jobs-finished-tab').click

          wait_for_requests

          expect(page).to have_selector('[data-testid="jobs-finished-tab"]')
          expect(page).to have_content 'No jobs to show'
          expect(page).to have_button 'Cancel all jobs'
        end
      end
    end
  end
end

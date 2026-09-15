# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'User views project artifacts page', :js, feature_category: :job_artifacts do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:pipeline) { create(:ci_empty_pipeline, project: project) }
  let_it_be(:job_with_artifacts) { create(:ci_build, :artifacts, name: 'test1', pipeline: pipeline) }
  let_it_be(:job_with_trace) { create(:ci_build, :trace_artifact, name: 'test3', pipeline: pipeline) }
  let_it_be(:job_without_artifacts) { create(:ci_build, name: 'test2', pipeline: pipeline) }

  let(:path) { project_artifacts_path(project) }

  context 'when browsing artifacts page' do
    before do
      visit(path)

      wait_for_requests
    end

    it 'lists the project jobs and their artifacts' do
      page.within('main#content-body') do
        page.within('table thead') do
          expect(page).to have_content('Artifacts')
            .and have_content('Job')
            .and have_content('Size')
        end

        all_by_testid('job-artifacts-count').each(&:click)

        expect(page).to have_content(job_with_artifacts.name)
        expect(page).to have_content(job_with_trace.name)
        expect(page).not_to have_content(job_without_artifacts.name)

        expect(page).to have_content('archive').and have_content('metadata')
        expect(page).to have_content('trace')
      end
    end

    it 'disables the download and browse buttons for a job without an archive', :aggregate_failures do
      within_job_row(job_with_trace) do
        expect(page).to have_button('Download', disabled: true)
        expect(page).to have_button('Browse', disabled: true)
      end
    end

    it 'hides every delete control from a user who cannot delete artifacts', :aggregate_failures do
      expect(page).to have_content(job_with_artifacts.name)
      expect(page).to have_no_testid('select-all-artifacts-checkbox', visible: :all)
      expect(page).to have_no_button('Delete')

      expand_artifacts_of(job_with_artifacts)

      expect(page).to have_content('ci_build_artifacts.zip')
      expect(page).to have_no_button('Delete ci_build_artifacts.zip')
    end
  end

  context 'when the user can delete artifacts' do
    let_it_be(:maintainer) { create(:user, maintainer_of: project) }

    before do
      sign_in(maintainer)
      visit(path)
    end

    it 'deletes a single artifact and keeps the job expanded', :aggregate_failures do
      expand_artifacts_of(job_with_artifacts)

      expect(page).to have_content('ci_build_artifacts_metadata.gz')

      click_button 'Delete ci_build_artifacts_metadata.gz'

      within_modal do
        expect(page).to have_content('Delete ci_build_artifacts_metadata.gz?')

        click_button 'Delete artifact'
      end

      expect(page).not_to have_content('ci_build_artifacts_metadata.gz')
      expect(page).to have_content('ci_build_artifacts.zip')
    end

    it 'offers the bulk selection controls', :aggregate_failures do
      expect(page).to have_unchecked_field('Select all artifacts')

      within_job_row(job_with_artifacts) do
        expect(page).to have_button('Delete')
      end
    end

    it 'selects 1 then 2 artifacts with the row checkboxes, counting them in the banner', :aggregate_failures do
      check "Select artifacts for #{job_with_artifacts.name}"

      expect(page).to have_content('2 artifacts selected')
      expect(page).to have_checked_field('Select all artifacts')

      check "Select artifacts for #{job_with_trace.name}"

      expect(page).to have_content('3 artifacts selected')
    end

    it 'selects all artifacts, clears the selection, then bulk deletes them', :aggregate_failures do
      expect(page).to have_content(job_with_artifacts.name)

      check 'Select all artifacts'

      expect(page).to have_content('3 artifacts selected')
      expect(page).to have_checked_field("Select artifacts for #{job_with_artifacts.name}")
      expect(page).to have_checked_field("Select artifacts for #{job_with_trace.name}")

      click_button 'Clear selection'

      expect(page).not_to have_content('artifacts selected')
      expect(page).to have_unchecked_field('Select all artifacts')

      check 'Select all artifacts'
      click_button 'Delete selected'

      within_modal do
        expect(page).to have_content('Delete 3 artifacts?')

        click_button 'Delete 3 artifacts'
      end

      expect(page).to have_content('3 selected artifacts deleted')
      expect(page).not_to have_content(job_with_artifacts.name)
      expect(page).not_to have_content(job_with_trace.name)
    end
  end

  context 'when an artifact has expired' do
    let_it_be(:job_with_expired_artifact) do
      create(:ci_build, name: 'test4', pipeline: pipeline).tap do |job|
        create(:ci_job_artifact, :archive, :expired, :public, job: job)
      end
    end

    before do
      visit(path)
    end

    it 'marks the artifact as expired' do
      expand_artifacts_of(job_with_expired_artifact)

      expect(page).to have_content('Expired')
    end
  end

  def job_row(job)
    find_by_testid('job-artifact-table-row', text: job.name)
  end

  def within_job_row(job, &block)
    within(job_row(job), &block)
  end

  def expand_artifacts_of(job)
    within_job_row(job) { find_by_testid('job-artifacts-count').click }
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Artifact file', :js, feature_category: :job_artifacts do
  let(:project) { create(:project, :public) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }
  let(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

  def visit_file(path)
    visit file_path(path)
  end

  def file_path(path)
    file_project_job_artifacts_path(project, build, path)
  end

  context 'Text file' do
    before do
      visit_file('other_artifacts_0.1.2/doc_sample.txt')

      wait_for_requests
    end

    it 'displays an error' do
      aggregate_failures do
        # shows an error message
        expect(page).to have_content('The source could not be displayed because it is stored as a job artifact. You can download it instead.')

        # does not show a viewer switcher
        expect(page).not_to have_selector('.js-blob-viewer-switcher')

        # does not show a copy button
        expect(page).not_to have_selector('.js-copy-blob-source-btn')

        # shows a download button
        expect(page).to have_link('Download')
      end
    end
  end

  context 'JPG file' do
    before do
      visit_file('rails_sample.jpg')

      wait_for_requests
    end

    it 'displays the blob' do
      aggregate_failures do
        # shows rendered image
        expect(page).to have_selector('.image_file img')

        # does not show a viewer switcher
        expect(page).not_to have_selector('.js-blob-viewer-switcher')

        # does not show a copy button
        expect(page).not_to have_selector('.js-copy-blob-source-btn')

        # shows a download button
        expect(page).to have_link('Download')
      end
    end
  end

  context 'when visiting old URL' do
    let(:file_url) do
      file_path('other_artifacts_0.1.2/doc_sample.txt')
    end

    before do
      visit file_url.sub('/-/jobs', '/builds')
    end

    it "redirects to new URL" do
      expect(page).to have_current_path(file_url, ignore_query: true)
    end
  end
end

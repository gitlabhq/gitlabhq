require 'spec_helper'

feature 'Browse artifact', :js do
  let(:project) { create(:project, :public) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }
  let(:job) { create(:ci_build, :artifacts, pipeline: pipeline) }
  let(:browse_url) do
    browse_path('other_artifacts_0.1.2')
  end

  def browse_path(path)
    browse_project_job_artifacts_path(project, job, path)
  end

  context 'when visiting old URL' do
    before do
      visit browse_url.sub('/-/jobs', '/builds')
    end

    it "redirects to new URL" do
      expect(page.current_path).to eq(browse_url)
    end
  end

  context 'when browsing a directory with an text file' do
    let(:txt_entry) { job.artifacts_metadata_entry('other_artifacts_0.1.2/doc_sample.txt') }

    before do
      allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
      allow(Gitlab.config.pages).to receive(:artifacts_server).and_return(true)

      visit browse_url
    end

    it "shows external link icon and styles" do
      link = first('.tree-item-file-external-link')

      expect(page).to have_link('doc_sample.txt', href: file_project_job_artifacts_path(project, job, path: txt_entry.blob.path))
      expect(link[:target]).to eq('_blank')
      expect(link[:rel]).to include('noopener')
      expect(link[:rel]).to include('noreferrer')
      expect(page).to have_selector('.js-artifact-tree-external-icon')
    end
  end
end

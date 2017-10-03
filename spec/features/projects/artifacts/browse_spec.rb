require 'spec_helper'

feature 'Browse artifact', :js do
  include ArtifactHelper

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

  context 'when browsing a directory with an HTML file' do
    let(:html_entry) { job.artifacts_metadata_entry("other_artifacts_0.1.2/index.html") }

    before do
      allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
      allow(Gitlab.config.pages).to receive(:artifacts_server).and_return(true)

      visit browse_url
    end

    it "shows external link icon and styles" do
      link = first('.tree-item-file-external-link')

      expect(link).to have_content('index.html')
      expect(link[:href]).to eq(html_artifact_url(project, job, html_entry.blob))
      expect(page).to have_selector('.js-artifact-tree-external-icon')
    end
  end
end

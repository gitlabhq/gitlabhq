require 'spec_helper'

feature 'Browse artifact', :js do
  let(:project) { create(:project, :public) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, sha: project.commit.sha, ref: 'master') }
  let(:job) { create(:ci_build, :artifacts, pipeline: pipeline) }

  def browse_path(path)
    browse_project_job_artifacts_path(project, job, path)
  end

  context 'when visiting old URL' do
    let(:browse_url) do
      browse_path('other_artifacts_0.1.2')
    end

    before do
      visit browse_url.sub('/-/jobs', '/builds')
    end

    it "redirects to new URL" do
      expect(page.current_path).to eq(browse_url)
    end
  end
end

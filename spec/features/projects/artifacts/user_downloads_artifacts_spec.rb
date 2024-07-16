# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User downloads artifacts", feature_category: :job_artifacts do
  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:pipeline) { create(:ci_empty_pipeline, status: :success, sha: project.commit.id, project: project) }
  let_it_be(:job) { create(:ci_build, :artifacts, :success, pipeline: pipeline) }

  shared_examples "downloading" do
    it "downloads the zip" do
      expect(page.response_headers['Content-Disposition']).to eq(%(attachment; filename="#{job.artifacts_file.filename}"; filename*=UTF-8''#{job.artifacts_file.filename}))
      expect(page.response_headers['Content-Transfer-Encoding']).to eq("binary")
      expect(page.response_headers['Content-Type']).to eq("application/zip")
      expect(page.source.b).to eq(job.artifacts_file.file.read.b)
    end
  end

  context "when downloading" do
    before do
      visit(url)
    end

    context "via job id" do
      let(:url) { download_project_job_artifacts_path(project, job) }

      it_behaves_like "downloading"
    end

    context "via branch name and job name" do
      let(:url) { latest_succeeded_project_artifacts_path(project, "#{pipeline.ref}/download", job: job.name) }

      it_behaves_like "downloading"
    end

    context "via SHA" do
      let(:url) { latest_succeeded_project_artifacts_path(project, "#{pipeline.sha}/download", job: job.name) }

      it_behaves_like "downloading"
    end
  end
end

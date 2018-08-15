require "spec_helper"

describe "User downloads artifacts" do
  set(:project) { create(:project, :public) }
  set(:pipeline) { create(:ci_empty_pipeline, status: :success, project: project) }
  set(:job) { create(:ci_build, :artifacts, :success, pipeline: pipeline) }

  shared_examples "downloading" do
    it "downloads the zip" do
      expect(page.response_headers["Content-Disposition"]).to eq(%Q{attachment; filename="#{job.artifacts_archive_file.filename}"})
      expect(page.response_headers['Content-Transfer-Encoding']).to eq("binary")
      expect(page.response_headers['Content-Type']).to eq("application/zip")
      expect(page.source.b).to eq(job.artifacts_archive_file.file.read.b)
    end
  end

  context "when downloading" do
    before do
      visit(url)
    end

    context "via job id" do
      set(:url) { download_project_job_artifacts_path(project, job) }

      it_behaves_like "downloading"
    end

    context "via branch name and job name" do
      set(:url) { latest_succeeded_project_artifacts_path(project, "#{pipeline.ref}/download", job: job.name) }

      it_behaves_like "downloading"
    end

    context "via clicking the `Download` button" do
      set(:url) { project_job_path(project, job) }

      before do
        click_link("Download")
      end

      it_behaves_like "downloading"
    end
  end
end

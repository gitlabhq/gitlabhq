# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User browses artifacts", feature_category: :job_artifacts do
  let(:project) { create(:project, :public) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }
  let(:job) { create(:ci_build, :artifacts, pipeline: pipeline) }
  let(:browse_url) { browse_project_job_artifacts_path(project, job, "other_artifacts_0.1.2") }

  context "when visiting old URL" do
    it "redirects to new URL" do
      visit(browse_url.sub("/-/jobs", "/builds"))

      expect(page).to have_current_path(browse_url, ignore_query: true)
    end
  end

  context "when browsing artifacts root directory" do
    before do
      visit(browse_project_job_artifacts_path(project, job))
    end

    it "renders a link to the job in the breadcrumbs", :js do
      within_testid('breadcrumb-links') do
        expect(page).to have_link("##{job.id}", href: project_job_path(project, job))
      end
    end

    it "shows artifacts" do
      expect(page).not_to have_selector(".build-sidebar")

      page.within(".tree-table") do
        expect(page).to have_no_content("..")
                   .and have_content("other_artifacts_0.1.2")
                   .and have_content("ci_artifacts.txt 27 B")
                   .and have_content("rails_sample.jpg 34.4 KiB")
      end

      page.within(".build-header") do
        expect(page).to have_content("Job ##{job.id} in pipeline ##{pipeline.id} for #{pipeline.short_sha}")
      end
    end

    it "shows an artifact" do
      click_link("ci_artifacts.txt")

      expect(page).to have_link("download it")
    end
  end

  context "when browsing a directory with UTF-8 characters in its name" do
    before do
      visit(browse_project_job_artifacts_path(project, job))
    end

    it "shows correct content", :js do
      page.within(".tree-table") do
        click_link("tests_encoding")

        expect(page).to have_no_content("non-utf8-dir")

        click_link("utf8 test dir ✓")

        expect(page).to have_content("..").and have_content("regular_file_2")
      end
    end
  end

  context "when browsing a directory with a text file" do
    let(:txt_entry) { job.artifacts_metadata_entry("other_artifacts_0.1.2/doc_sample.txt") }

    before do
      allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
      allow(Gitlab.config.pages).to receive(:artifacts_server).and_return(true)
    end

    context "when the project is public" do
      before do
        visit(browse_url)
      end

      it "shows correct content" do
        expect(page)
          .to have_link(
            "doc_sample.txt",
            href: external_file_project_job_artifacts_path(project, job, path: txt_entry.blob.path)
          ).and have_selector(".js-artifact-tree-external-icon")

        page.within(".tree-table") do
          expect(page).to have_content("..").and have_content("another-subdirectory")
        end

        page.within(".repo-breadcrumb") do
          expect(page).to have_content("other_artifacts_0.1.2")
        end
      end
    end

    context "when the project is private" do
      let!(:private_project) { create(:project, :private) }
      let(:pipeline) { create(:ci_empty_pipeline, project: private_project) }
      let(:job) { create(:ci_build, :artifacts, pipeline: pipeline) }
      let(:user) { create(:user) }

      before do
        private_project.add_developer(user)

        sign_in(user)

        visit(browse_project_job_artifacts_path(private_project, job, "other_artifacts_0.1.2"))
      end

      it { expect(page).to have_link("doc_sample.txt").and have_no_selector(".js-artifact-tree-external-icon") }
    end

    context "when the project is private and pages access control is enabled" do
      let!(:private_project) { create(:project, :private) }
      let(:pipeline) { create(:ci_empty_pipeline, project: private_project) }
      let(:job) { create(:ci_build, :artifacts, pipeline: pipeline) }
      let(:user) { create(:user) }

      before do
        private_project.add_developer(user)

        allow(Gitlab.config.pages).to receive(:access_control).and_return(true)

        sign_in(user)

        visit(browse_project_job_artifacts_path(private_project, job, "other_artifacts_0.1.2"))
      end

      it { expect(page).to have_link("doc_sample.txt").and have_selector(".js-artifact-tree-external-icon") }
    end
  end
end

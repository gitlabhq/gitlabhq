require 'spec_helper'

feature 'Only allow merge requests to be merged if the build succeeds', feature: true, js: true do
  let(:user) { create(:user) }

  let(:project)       { create(:project, :public) }
  let(:merge_request) { create(:merge_request_with_diffs, source_project: project, author: user) }

  before do
    login_as user

    project.team << [user, :master]
  end

  context "project hasn't ci enabled" do
    it "allows MR to be merged" do
      visit_merge_request(merge_request)
      expect(page).to have_button "Accept Merge Request"
    end
  end

  context "when project has ci enabled" do
    let!(:ci_commit) { create(:ci_commit, project: project, sha: merge_request.last_commit.id, ref: merge_request.source_branch) }
    let!(:ci_build) { create(:ci_build, commit: ci_commit) }

    before do
      project.enable_ci
    end

    context "when merge requests can only be merged if the build succeeds" do
      before do
        project.update_attribute(:only_allow_merge_if_build_succeeds, true)
      end

      context "when ci is running" do
        it "doesn't allow to merge immediately" do
          ci_commit.statuses.update_all(status: :pending)
          visit_merge_request(merge_request)

          expect(page).to have_button "Merge When Build Succeeds"
          expect(page).to_not have_button "Select Merge Moment"
        end
      end

      context "when ci failed" do
        it "doesn't allow MR to be merged" do
          ci_commit.statuses.update_all(status: :failed)
          visit_merge_request(merge_request)

          expect(page).to_not have_button "Accept Merge Request"
          expect(page).to have_content("Please retry the build or push code to fix the failure.")
        end
      end

      context "when ci succeed" do
        it "allows MR to be merged" do
          ci_commit.statuses.update_all(status: :success)
          visit_merge_request(merge_request)

          expect(page).to have_button "Accept Merge Request"
        end
      end
    end

    context "when merge requests can be merged when the build failed" do
      before do
        project.update_attribute(:only_allow_merge_if_build_succeeds, false)
      end

      context "when ci is running" do
        it "allows MR to be merged immediately" do
          ci_commit.statuses.update_all(status: :pending)
          visit_merge_request(merge_request)

          expect(page).to have_button "Merge When Build Succeeds"

          click_button "Select Merge Moment"
          expect(page).to have_content "Merge Immediately"
        end
      end

      context "when ci failed" do
        it "allows MR to be merged" do
          ci_commit.statuses.update_all(status: :failed)
          visit_merge_request(merge_request)

          expect(page).to have_button "Accept Merge Request"
        end
      end

      context "when ci succeed" do
        it "allows MR to be merged" do
          ci_commit.statuses.update_all(status: :success)
          visit_merge_request(merge_request)

          expect(page).to have_button "Accept Merge Request"
        end
      end
    end
  end

  def visit_merge_request(merge_request)
    visit namespace_project_merge_request_path(merge_request.project.namespace, merge_request.project, merge_request)
  end
end

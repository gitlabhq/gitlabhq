require 'spec_helper'

describe "Commits" do
  include CiStatusHelper

  let(:project) { create(:project) }

  describe "CI" do
    before do
      login_as :user
      project.team << [@user, :master]
      @ci_project = project.ensure_gitlab_ci_project
      @commit = FactoryGirl.create :ci_commit, gl_project: project, sha: project.commit.sha
      @build = FactoryGirl.create :ci_build, commit: @commit
      @generic_status = FactoryGirl.create :generic_commit_status, commit: @commit
    end

    before do
      stub_ci_commit_to_return_yaml_file
    end

    describe "GET /:project/commits/:sha" do
      before do
        visit ci_status_path(@commit)
      end

      it { expect(page).to have_content @commit.sha[0..7] }
      it { expect(page).to have_content @commit.git_commit_message }
      it { expect(page).to have_content @commit.git_author_name }
    end

    describe "Cancel all builds" do
      it "cancels commit" do
        visit ci_status_path(@commit)
        click_on "Cancel all"
        expect(page).to have_content "canceled"
      end
    end

    describe "Cancel build" do
      it "cancels build" do
        visit ci_status_path(@commit)
        click_on "Cancel"
        expect(page).to have_content "canceled"
      end
    end

    describe ".gitlab-ci.yml not found warning" do
      it "does not show warning" do
        visit ci_status_path(@commit)
        expect(page).not_to have_content ".gitlab-ci.yml not found in this commit"
      end

      it "shows warning" do
        stub_ci_commit_yaml_file(nil)
        visit ci_status_path(@commit)
        expect(page).to have_content ".gitlab-ci.yml not found in this commit"
      end
    end
  end
end

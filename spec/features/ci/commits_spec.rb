require 'spec_helper'

describe "Commits" do
  context "Authenticated user" do
    before do
      login_as :user
      @project = FactoryGirl.create :project
      @commit = FactoryGirl.create :commit, project: @project
      @build = FactoryGirl.create :build, commit: @commit
    end

    describe "GET /:project/commits/:sha" do
      before do
        visit project_ref_commit_path(@project, @commit.ref, @commit.sha)
      end

      it { page.should have_content @commit.sha[0..7] }
      it { page.should have_content @commit.git_commit_message }
      it { page.should have_content @commit.git_author_name }
    end

    describe "Cancel commit" do
      it "cancels commit" do
        visit project_ref_commit_path(@project, @commit.ref, @commit.sha)
        click_on "Cancel"

        page.should have_content "canceled"
      end
    end

    describe ".gitlab-ci.yml not found warning" do
      it "does not show warning" do
        visit project_ref_commit_path(@project, @commit.ref, @commit.sha)

        page.should_not have_content ".gitlab-ci.yml not found in this commit"
      end

      it "shows warning" do
        @commit.push_data[:ci_yaml_file] = nil
        @commit.save

        visit project_ref_commit_path(@project, @commit.ref, @commit.sha)

        page.should have_content ".gitlab-ci.yml not found in this commit"
      end
    end
  end

  context "Public pages" do
    before do
      @project = FactoryGirl.create :public_project
      @commit = FactoryGirl.create :commit, project: @project
      @build = FactoryGirl.create :build, commit: @commit
    end

    describe "GET /:project/commits/:sha" do
      before do
        visit project_ref_commit_path(@project, @commit.ref, @commit.sha)
      end

      it { page.should have_content @commit.sha[0..7] }
      it { page.should have_content @commit.git_commit_message }
      it { page.should have_content @commit.git_author_name }
    end
  end
end

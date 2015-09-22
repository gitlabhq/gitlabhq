require 'spec_helper'

describe "Commits" do
  include Ci::CommitsHelper

  context "Authenticated user" do
    before do
      @project = FactoryGirl.create :ci_project
      @commit = FactoryGirl.create :ci_commit, project: @project
      @build = FactoryGirl.create :ci_build, commit: @commit
      login_as :user
      @project.gl_project.team << [@user, :master]
    end

    describe "GET /:project/commits/:sha" do
      before do
        visit ci_commit_path(@commit)
      end

      it { expect(page).to have_content @commit.sha[0..7] }
      it { expect(page).to have_content @commit.git_commit_message }
      it { expect(page).to have_content @commit.git_author_name }
    end

    describe "Cancel commit" do
      it "cancels commit" do
        visit ci_commit_path(@commit)
        click_on "Cancel"

        expect(page).to have_content "canceled"
      end
    end

    describe ".gitlab-ci.yml not found warning" do
      it "does not show warning" do
        visit ci_commit_path(@commit)

        expect(page).not_to have_content ".gitlab-ci.yml not found in this commit"
      end

      it "shows warning" do
        @commit.push_data[:ci_yaml_file] = nil
        @commit.save

        visit ci_commit_path(@commit)

        expect(page).to have_content ".gitlab-ci.yml not found in this commit"
      end
    end
  end

  context "Public pages" do
    before do
      @project = FactoryGirl.create :ci_public_project
      @commit = FactoryGirl.create :ci_commit, project: @project
      @build = FactoryGirl.create :ci_build, commit: @commit
    end

    describe "GET /:project/commits/:sha" do
      before do
        visit ci_commit_path(@commit)
      end

      it { expect(page).to have_content @commit.sha[0..7] }
      it { expect(page).to have_content @commit.git_commit_message }
      it { expect(page).to have_content @commit.git_author_name }
    end
  end
end

require 'spec_helper'

describe "Commits" do
  include Ci::CommitsHelper

  context "Authenticated user" do
    before do
      @commit = FactoryGirl.create :ci_commit
      @build = FactoryGirl.create :ci_build, commit: @commit
      login_as :user
      @commit.project.gl_project.team << [@user, :master]
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
        @commit_no_yaml = FactoryGirl.create :ci_empty_commit

        visit ci_commit_path(@commit_no_yaml)

        expect(page).to have_content ".gitlab-ci.yml not found in this commit"
      end
    end
  end

  context "Public pages" do
    before do
      @commit = FactoryGirl.create :ci_commit
      @commit.project.public = true
      @commit.project.save

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

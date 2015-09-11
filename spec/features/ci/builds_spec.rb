require 'spec_helper'

describe "Builds" do
  context :private_project do
    before do
      @project = FactoryGirl.create :ci_project
      @commit = FactoryGirl.create :ci_commit, project: @project
      @build = FactoryGirl.create :ci_build, commit: @commit
      login_as :user
      @project.gl_project.team << [@user, :master]
    end

    describe "GET /:project/builds/:id" do
      before do
        visit ci_project_build_path(@project, @build)
      end

      it { expect(page).to have_content @commit.sha[0..7] }
      it { expect(page).to have_content @commit.git_commit_message }
      it { expect(page).to have_content @commit.git_author_name }
    end

    describe "GET /:project/builds/:id/cancel" do
      before do
        @build.run!
        visit cancel_ci_project_build_path(@project, @build)
      end

      it { expect(page).to have_content 'canceled' }
      it { expect(page).to have_content 'Retry' }
    end

    describe "POST /:project/builds/:id/retry" do
      before do
        @build.cancel!
        visit ci_project_build_path(@project, @build)
        click_link 'Retry'
      end

      it { expect(page).to have_content 'pending' }
      it { expect(page).to have_content 'Cancel' }
    end
  end

  context :public_project do
    describe "Show page public accessible" do
      before do
        @project = FactoryGirl.create :ci_public_project
        @commit = FactoryGirl.create :ci_commit, project: @project
        @runner = FactoryGirl.create :ci_specific_runner
        @build = FactoryGirl.create :ci_build, commit: @commit, runner: @runner

        stub_gitlab_calls
        visit ci_project_build_path(@project, @build)
      end

      it { expect(page).to have_content @commit.sha[0..7] }
    end
  end
end

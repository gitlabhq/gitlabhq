require 'spec_helper'

describe "Builds" do
  before do
    login_as(:user)
    @commit = FactoryGirl.create :ci_commit
    @build = FactoryGirl.create :ci_build, commit: @commit
    @gl_project = @commit.project.gl_project
    @gl_project.team << [@user, :master]
  end

  describe "GET /:project/builds" do
    context "Running scope" do
      before do
        @build.run!
        visit namespace_project_builds_path(@gl_project.namespace, @gl_project)
      end

      it { expect(page).to have_content 'Running' }
      it { expect(page).to have_content 'Cancel all' }
      it { expect(page).to have_content @build.short_sha }
      it { expect(page).to have_content @build.ref }
      it { expect(page).to have_content @build.name }
    end

    context "Finished scope" do
      before do
        @build.run!
        visit namespace_project_builds_path(@gl_project.namespace, @gl_project, scope: :finished)
      end

      it { expect(page).to have_content 'No builds to show' }
      it { expect(page).to have_content 'Cancel all' }
    end

    context "All builds" do
      before do
        @gl_project.ci_builds.running_or_pending.each(&:success)
        visit namespace_project_builds_path(@gl_project.namespace, @gl_project, scope: :all)
      end

      it { expect(page).to have_content 'All' }
      it { expect(page).to have_content @build.short_sha }
      it { expect(page).to have_content @build.ref }
      it { expect(page).to have_content @build.name }
      it { expect(page).to_not have_content 'Cancel all' }
    end
  end

  describe "GET /:project/builds/:id/cancel_all" do
    before do
      @build.run!
      visit cancel_all_namespace_project_builds_path(@gl_project.namespace, @gl_project)
    end

    it { expect(page).to have_content 'No builds to show' }
    it { expect(page).to_not have_content 'Cancel all' }
  end

  describe "GET /:project/builds/:id" do
    before do
      visit namespace_project_build_path(@gl_project.namespace, @gl_project, @build)
    end

    it { expect(page).to have_content @commit.sha[0..7] }
    it { expect(page).to have_content @commit.git_commit_message }
    it { expect(page).to have_content @commit.git_author_name }
  end

  describe "GET /:project/builds/:id/cancel" do
    before do
      @build.run!
      visit cancel_namespace_project_build_path(@gl_project.namespace, @gl_project, @build)
    end

    it { expect(page).to have_content 'canceled' }
    it { expect(page).to have_content 'Retry' }
  end

  describe "POST /:project/builds/:id/retry" do
    before do
      visit cancel_namespace_project_build_path(@gl_project.namespace, @gl_project, @build)
      click_link 'Retry'
    end

    it { expect(page).to have_content 'pending' }
    it { expect(page).to have_content 'Cancel' }
  end
end

require 'spec_helper'

describe "Builds" do
  before do
    login_as(:user)
    @commit = FactoryGirl.create :ci_commit
    @build = FactoryGirl.create :ci_build, commit: @commit
    @gl_project = @commit.project.gl_project
    @gl_project.team << [@user, :master]
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

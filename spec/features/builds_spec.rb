require 'spec_helper'

describe "Builds" do
  let(:artifacts_file) { fixture_file_upload(Rails.root + 'spec/fixtures/banana_sample.gif', 'image/gif') }

  before do
    login_as(:user)
    @commit = FactoryGirl.create :ci_commit
    @build = FactoryGirl.create :ci_build, commit: @commit
    @project = @commit.project
    @project.team << [@user, :developer]
  end

  describe "GET /:project/builds" do
    context "Running scope" do
      before do
        @build.run!
        visit namespace_project_builds_path(@project.namespace, @project, scope: :running)
      end

      it { expect(page).to have_selector('.nav-links li.active', text: 'Running') }
      it { expect(page).to have_link 'Cancel running' }
      it { expect(page).to have_content @build.short_sha }
      it { expect(page).to have_content @build.ref }
      it { expect(page).to have_content @build.name }
    end

    context "Finished scope" do
      before do
        @build.run!
        visit namespace_project_builds_path(@project.namespace, @project, scope: :finished)
      end

      it { expect(page).to have_selector('.nav-links li.active', text: 'Finished') }
      it { expect(page).to have_content 'No builds to show' }
      it { expect(page).to have_link 'Cancel running' }
    end

    context "All builds" do
      before do
        @project.builds.running_or_pending.each(&:success)
        visit namespace_project_builds_path(@project.namespace, @project)
      end

      it { expect(page).to have_selector('.nav-links li.active', text: 'All') }
      it { expect(page).to have_content @build.short_sha }
      it { expect(page).to have_content @build.ref }
      it { expect(page).to have_content @build.name }
      it { expect(page).to_not have_link 'Cancel running' }
    end
  end

  describe "POST /:project/builds/:id/cancel_all" do
    before do
      @build.run!
      visit namespace_project_builds_path(@project.namespace, @project)
      click_link "Cancel running"
    end

    it { expect(page).to have_selector('.nav-links li.active', text: 'All') }
    it { expect(page).to have_content 'canceled' }
    it { expect(page).to have_content @build.short_sha }
    it { expect(page).to have_content @build.ref }
    it { expect(page).to have_content @build.name }
    it { expect(page).to_not have_link 'Cancel running' }
  end

  describe "GET /:project/builds/:id" do
    before do
      visit namespace_project_build_path(@project.namespace, @project, @build)
    end

    it { expect(page).to have_content @commit.sha[0..7] }
    it { expect(page).to have_content @commit.git_commit_message }
    it { expect(page).to have_content @commit.git_author_name }

    context "Download artifacts" do
      before do
        @build.update_attributes(artifacts_file: artifacts_file)
        visit namespace_project_build_path(@project.namespace, @project, @build)
      end

      it 'has button to download artifacts' do
        page.within('.artifacts') do
          expect(page).to have_content 'Download'
        end
      end
    end
  end

  describe "POST /:project/builds/:id/cancel" do
    before do
      @build.run!
      visit namespace_project_build_path(@project.namespace, @project, @build)
      click_link "Cancel"
    end

    it { expect(page).to have_content 'canceled' }
    it { expect(page).to have_content 'Retry' }
  end

  describe "POST /:project/builds/:id/retry" do
    before do
      @build.run!
      visit namespace_project_build_path(@project.namespace, @project, @build)
      click_link "Cancel"
      click_link 'Retry'
    end

    it { expect(page).to have_content 'pending' }
    it { expect(page).to have_content 'Cancel' }
  end

  describe "GET /:project/builds/:id/download" do
    before do
      @build.update_attributes(artifacts_file: artifacts_file)
      visit namespace_project_build_path(@project.namespace, @project, @build)
      page.within('.artifacts') { click_link 'Download' }
    end

    it { expect(page.response_headers['Content-Type']).to eq(artifacts_file.content_type) }
  end
end
